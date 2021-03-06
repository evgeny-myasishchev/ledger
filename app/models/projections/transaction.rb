class Projections::Transaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections

  belongs_to :account, primary_key: :aggregate_id

  # Gets transfer counterpart. For sending transaction that would be the receiving and vice versa.
  def get_transfer_counterpart
    raise "Transaction '#{transaction_id}' is not involved in transfer." unless is_transfer

    # This ons is receiving. Finding sending
    return self.class.find_by transaction_id: sending_transaction_id unless transaction_id == sending_transaction_id

    # This one is sending. Finding receiving
    self.class.find_by 'sending_transaction_id = ? AND receiving_transaction_id = transaction_id', sending_transaction_id
  end

  def add_tag(the_id)
    wrapped_tag_id = "{#{the_id}}"
    return if !tag_ids.nil? && tag_ids.include?(wrapped_tag_id)
    self.tag_ids ||= ''
    self.tag_ids << ',' unless self.tag_ids.blank?
    self.tag_ids << wrapped_tag_id
    tag_ids_will_change!
  end

  def remove_tag(tag_id)
    wrapped = "{#{tag_id}}"
    index = self.tag_ids.index(wrapped)
    replacement = (index && index > 0 && (index + wrapped.length < self.tag_ids.length)) ? ',' : ''
    tag_ids_will_change! if self.tag_ids.gsub! /,?\{#{tag_id}\},?/, replacement
  end

  def self.get_root_data(user, account_id, limit: 25)
    account = account_id.nil? ? nil : Account.ensure_authorized!(account_id, user)
    transactions = build_search_query user, account
    root_data = {
      transactions_total: transactions.count(:id),
      transactions_limit: limit,
      transactions: transactions.take(limit)
    }
    if account
      root_data[:account_balance] = account.balance
      root_data[:pending_balance] = account.pending_balance
    end
    root_data
  end

  def self.search(user, account_id, criteria: {}, offset: 0, limit: 25, with_total: false)
    account = account_id.nil? ? nil : Account.ensure_authorized!(account_id, user)
    query = build_search_query(user, account, criteria: criteria)
    result = {
      transactions: query.offset(offset).take(limit)
    }
    result[:transactions_total] = query.count(:id) if with_total
    result
  end

  # criteria is a hash that accepts following keys
  # * tag_ids - array of tag ids
  # * comment
  # * amount - exact amount to find
  # * from - date from
  # * to - date to
  def self.build_search_query(user, account, criteria: {})
    raise 'User or Account should be provided.' if user.nil? && account.nil?
    criteria ||= {}
    query = account.nil? ? Transaction.joins(:account).where('projections_accounts.authorized_user_ids LIKE ?', "%{#{user.id}}%")
    : Transaction.where(account_id: account.aggregate_id)
    query = query.select(:id, :transaction_id, :account_id, :type_id, :amount, :tag_ids, :comment, :date,
                         :is_transfer, :sending_account_id, :sending_transaction_id,
                         :receiving_account_id, :receiving_transaction_id, :reported_by, :reported_at, :is_pending)
    query = query.order(date: :desc)
    if criteria[:tag_ids]
      tag_ids_search_query = ''
      criteria[:tag_ids].each do |_|
        tag_ids_search_query << ' or ' unless tag_ids_search_query.empty?
        tag_ids_search_query << 'tag_ids like ?'
      end
      query = query.where [tag_ids_search_query] + criteria[:tag_ids].map { |tag_id| "%{#{tag_id}}%" }
    end
    query = query.where Transaction.arel_table[:comment].matches("%#{criteria[:comment]}%") if criteria[:comment]
    query = query.where amount: criteria[:amount] if criteria[:amount]
    query = query.where 'date >= ?', criteria[:from] if criteria[:from]
    query = query.where 'date <= ?', criteria[:to] if criteria[:to]
    query
  end

  projection do
    on AccountRemoved do |event|
      Transaction.where(account_id: event.aggregate_id).delete_all
    end

    on_any PendingTransactionReported, PendingTransactionRestored do |event, headers|
      unless Transaction.exists?(transaction_id: event.aggregate_id) || event.account_id.nil?
        transaction = build_pending_transaction(event, headers) { |t| t.amount = parse_amount(event) }
        transaction.is_pending = true
        transaction.save!
      end
    end

    on PendingTransactionAdjusted do |event, headers|
      transaction = Transaction.find_by transaction_id: event.aggregate_id
      if transaction.nil?
        build_pending_transaction(event, headers) { |t| t.amount = parse_amount(event) }.save! unless event.account_id.nil?
      elsif event.account_id.nil?
        transaction.delete
      else
        transaction.attributes = build_transaction_attributes(event, headers) { |attr| attr[:amount] = parse_amount(event) }
        transaction.account_id = event.account_id
        transaction.tag_ids = nil
        assign_tags(event, transaction)
        transaction.save!
      end
    end

    on PendingTransactionRejected do |event, _|
      Transaction.where(transaction_id: event.aggregate_id).delete_all
    end

    on TransactionReported do |event, headers|
      transaction = Transaction.find_by transaction_id: event.transaction_id

      if transaction.nil?
        transaction = build_transaction(event, headers)
        transaction.save!
      elsif transaction.is_pending
        transaction.attributes = build_transaction_attributes(event, headers)
        transaction.tag_ids = nil
        transaction.is_pending = false
        assign_tags(event, transaction)
        transaction.save!
      end
    end

    on TransferSent do |event, headers|
      transaction = Transaction.find_by transaction_id: event.transaction_id
      return if !transaction.nil? && !transaction.is_pending # Adjusting pending transactions only
      transaction = build_transaction(event, headers) if transaction.nil?
      transaction.is_transfer = true
      transaction.is_pending = false
      transaction.type_id = Domain::Transaction::ExpenseTypeId
      transaction.sending_account_id = event.aggregate_id
      transaction.sending_transaction_id = event.transaction_id
      transaction.receiving_account_id = event.receiving_account_id
      transaction.save!
    end

    on TransferReceived do |event, headers|
      unless Transaction.exists?(transaction_id: event.transaction_id)
        transaction = build_transaction(event, headers)
        transaction.is_transfer = true
        transaction.type_id = Domain::Transaction::IncomeTypeId
        transaction.receiving_account_id = event.aggregate_id
        transaction.receiving_transaction_id = event.transaction_id
        transaction.sending_transaction_id = event.sending_transaction_id
        transaction.sending_account_id = event.sending_account_id
        transaction.save!
      end
    end

    on TransactionAmountAdjusted do |event|
      Transaction.where(transaction_id: event.transaction_id).update_all amount: event.amount
    end

    on TransactionCommentAdjusted do |event|
      Transaction.where(transaction_id: event.transaction_id).update_all comment: event.comment
    end

    on TransactionDateAdjusted do |event|
      Transaction.where(transaction_id: event.transaction_id).update_all date: event.date
    end

    on TransactionTagged do |event|
      transaction = Transaction.find_by_transaction_id(event.transaction_id)
      transaction.add_tag event.tag_id
      transaction.save!
    end

    on TransactionUntagged do |event|
      transaction = Transaction.find_by_transaction_id(event.transaction_id)
      transaction.remove_tag event.tag_id
      transaction.save!
    end

    on TransactionTypeConverted do |event|
      Transaction.where(transaction_id: event.transaction_id).update_all type_id: event.type_id
    end

    on TransactionRemoved do |event|
      if Transaction.exists?(transaction_id: event.transaction_id)
        transaction = Transaction.find_by_transaction_id(event.transaction_id)
        transaction.delete
      end
    end

    private

    def parse_amount(event)
      account = Projections::Account.select(:currency_code).find_by(aggregate_id: event.account_id)
      Money.parse(event.amount, Currency[account.currency_code]).integer_amount
    end

    def build_transaction(event, headers)
      transaction = Transaction.new build_transaction_attributes(event, headers)
      assign_tags event, transaction
      transaction
    end

    def build_pending_transaction(event, headers)
      transaction = Transaction.new build_transaction_attributes(event, headers)
      transaction.account_id = event.account_id
      transaction.transaction_id = event.aggregate_id
      transaction.is_pending = true
      assign_tags event, transaction
      yield(transaction) if block_given?
      transaction
    end

    def build_transaction_attributes(event, headers)
      attrs = {
        account_id: event.aggregate_id,
        amount: event.amount,
        comment: event.comment,
        date: event.date
      }
      attrs[:transaction_id] = event.transaction_id if event.respond_to?(:transaction_id)
      attrs[:type_id] = event.type_id if event.respond_to?(:type_id)
      if headers.key?(:user_id)
        attrs[:reported_by_id] = headers[:user_id]
        attrs[:reported_by] = User.where(id: headers[:user_id]).pluck(:email).first
      end
      attrs[:reported_at] = headers[:$commit_timestamp]
      yield(attrs) if block_given?
      attrs
    end

    def assign_tags(event, transaction)
      event.tag_ids.each { |tag_id| transaction.add_tag tag_id } unless event.tag_ids.nil?
    end
  end
end
