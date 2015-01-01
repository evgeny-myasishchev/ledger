class Projections::Transaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  belongs_to :account, primary_key: :aggregate_id
  
  # Gets transfer counterpart. For sending transaction that would be the receiving and vice versa.
  def get_transfer_counterpart
    raise "Transaction '#{transaction_id}' is not involved in transfer." unless is_transfer
    
    # This ons is receving. Finding sending
    return self.class.find_by transaction_id: sending_transaction_id unless transaction_id == sending_transaction_id
    
    # This one is sending. Finding receiving
    return self.class.find_by 'sending_transaction_id = ? AND receiving_transaction_id = transaction_id', sending_transaction_id
  end
  
  def add_tag(the_id)
    wrapped_tag_id = "{#{the_id}}"
    if !self.tag_ids.nil? && self.tag_ids.include?(wrapped_tag_id)
      return
    end
    self.tag_ids ||= ""
    self.tag_ids << ',' unless self.tag_ids.blank?
    self.tag_ids << wrapped_tag_id
    self.tag_ids_will_change!
  end
  
  def remove_tag(tag_id)
    wrapped = "{#{tag_id}}"
    index = self.tag_ids.index(wrapped)
    replacement = (index && index > 0 && (index + wrapped.length < self.tag_ids.length)) ? ',' : ''
    self.tag_ids_will_change! if self.tag_ids.gsub! /,?\{#{tag_id}\},?/, replacement
  end
  
  def self.get_root_data(user, account_id, limit: 25)
    account = account_id.nil? ? nil : Account.ensure_authorized!(account_id, user)
    transactions = build_search_query user, account
    root_data = {
      transactions_total: transactions.count(:id),
      transactions_limit: limit,
      transactions: transactions.take(limit)
    }
    root_data[:account_balance] = account.balance if account
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
  def self.build_search_query user, account, criteria: {}
    raise 'User or Account should be provided.' if user.nil? && account.nil?
    criteria = criteria || {}
    query = account.nil? ? Transaction.joins(:account).where('projections_accounts.authorized_user_ids LIKE ?', "%{#{user.id}}%")
      : Transaction.where(account_id: account.aggregate_id)
    query = query.select(:id, :transaction_id, :type_id, :amount, :tag_ids, :comment, :date, 
        :is_transfer, :sending_account_id, :sending_transaction_id, 
        :receiving_account_id, :receiving_transaction_id)
    query = query.order(date: :desc)
    if criteria[:tag_ids]
      tag_ids_serach_query = ''
      criteria[:tag_ids].each { |tag_id|
        tag_ids_serach_query << ' or ' unless tag_ids_serach_query.empty?
        tag_ids_serach_query << 'tag_ids like ?'
      }
      query = query.where [tag_ids_serach_query] + criteria[:tag_ids].map { |tag_id| "%{#{tag_id}}%" }
    end
    query = query.where 'comment like ?', "%#{criteria[:comment]}%" if criteria[:comment]
    query = query.where amount: criteria[:amount] if criteria[:amount]
    query = query.where 'date >= ?', criteria[:from] if criteria[:from]
    query = query.where 'date <= ?', criteria[:to] if criteria[:to]
    query
  end
  
  projection do
    on AccountRemoved do |event|
      Transaction.where(account_id: event.aggregate_id).delete_all
    end
    
    on TransactionReported do |event|
      unless Transaction.exists?(transaction_id: event.transaction_id)
        t = build_transaction(event)
        t.type_id = event.type_id
        t.save!
      end
    end
    
    on TransferSent do |event|
      unless Transaction.exists?(transaction_id: event.transaction_id)
        t = build_transaction(event)
        t.is_transfer = true
        t.type_id = Domain::Transaction::ExpenceTypeId
        t.sending_account_id = event.aggregate_id
        t.sending_transaction_id = event.transaction_id
        t.receiving_account_id = event.receiving_account_id
        t.save!
      end
    end
        
    on TransferReceived do |event|
      unless Transaction.exists?(transaction_id: event.transaction_id)
        t = build_transaction(event)
        t.is_transfer = true
        t.type_id = Domain::Transaction::IncomeTypeId
        t.receiving_account_id = event.aggregate_id
        t.receiving_transaction_id = event.transaction_id
        t.sending_transaction_id = event.sending_transaction_id
        t.sending_account_id = event.sending_account_id
        t.save!
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
        
    on TransactionRemoved do |event|
      if Transaction.exists?(transaction_id: event.transaction_id)
        transaction = Transaction.find_by_transaction_id(event.transaction_id)
        transaction.delete
      end
    end
    
    private def build_transaction event
      t = Transaction.new account_id: event.aggregate_id,
        transaction_id: event.transaction_id,
        amount: event.amount,
        comment: event.comment,
        date: event.date
      assign_tags event, t
      t
    end
    
    private def assign_tags event, transaction
      event.tag_ids.each { |tag_id| transaction.add_tag tag_id }
    end
  end
end
