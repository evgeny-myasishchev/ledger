class Projections::Account < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include Projections::UserAuthorizable
  include Loggable

  def self.get_user_accounts(user)
    Account.
        select(:aggregate_id, :name, :balance, :pending_balance, :currency_code, :unit, :sequential_number, :category_id, :is_closed).
        where('authorized_user_ids LIKE ?', "%{#{user.id}}%")
  end

  def ensure_authorized!(user)
    unless authorized_user_ids.include?("{#{user.id}}")
      raise Errors::AuthorizationFailedError.new "The user(id=#{user.id}) is not authorized on account(aggregate_id=#{aggregate_id})."
    end
    self
  end

  def self.ensure_authorized!(account_id, user)
    Account.find_by_aggregate_id(account_id).ensure_authorized! user
  end

  def currency
    Currency[currency_code]
  end

  def on_pending_transaction_reported(amount, type_id)
    pending_amount = parse_pending_amount(amount)
    self.pending_balance += pending_amount if type_id == Domain::Transaction::IncomeTypeId
    self.pending_balance += pending_amount if type_id == Domain::Transaction::RefundTypeId
    self.pending_balance -= pending_amount if type_id == Domain::Transaction::ExpenseTypeId
    logger.debug "Pending transaction '#{amount}' of type #{type_id} reported. Pending balance was #{self.pending_balance_was} and now #{self.pending_balance}"
  end

  def on_pending_transaction_adjusted(old_amount, old_type_id, new_amount, new_type_id)
    logger.debug 'Pending transaction adjusted. First rejecting it and then reporting again...'
    on_pending_transaction_rejected(old_amount, old_type_id)
    on_pending_transaction_reported(new_amount, new_type_id)
    logger.debug "Pending transaction adjusted. Pending balance was #{self.pending_balance_was} and now #{self.pending_balance}"
  end

  def on_pending_transaction_approved(amount, type_id)
    undo_pending_transaction(amount, type_id)
    logger.debug "Pending transaction '#{amount}' of type #{type_id} approved. Pending balance was #{self.pending_balance_was} and now #{self.pending_balance}"
  end


  def on_pending_transaction_rejected(amount, type_id)
    undo_pending_transaction(amount, type_id)
    logger.debug "Pending transaction '#{amount}' of type #{type_id} rejected. Pending balance was #{self.pending_balance_was} and now #{self.pending_balance}"
  end

  private

  def undo_pending_transaction(amount, type_id)
    pending_amount = parse_pending_amount(amount)
    self.pending_balance -= pending_amount if type_id == Domain::Transaction::IncomeTypeId
    self.pending_balance -= pending_amount if type_id == Domain::Transaction::RefundTypeId
    self.pending_balance += pending_amount if type_id == Domain::Transaction::ExpenseTypeId
  end

  def parse_pending_amount(amount)
    integer_amount = Money.parse(amount, currency).integer_amount
    logger.debug "Pending amount '#{amount}' parsed. Integer amount #{integer_amount}"
    integer_amount
  end

  projection do
    include Loggable
    
    on LedgerShared do |event|
      Account.where(ledger_id: event.aggregate_id).each { |a|
        a.authorize_user event.user_id
        a.save!
      }
    end

    on AccountCreated do |event|
      unless Account.exists? aggregate_id: event.aggregate_id
        ledger = Ledger.find_by_aggregate_id event.ledger_id
        Account.create!(aggregate_id: event.aggregate_id,
                        ledger_id: event.ledger_id,
                        sequential_number: event.sequential_number,
                        owner_user_id: ledger.owner_user_id,
                        name: event.name,
                        currency_code: event.currency_code,
                        unit: event.unit,
                        balance: event.initial_balance,
                        is_closed: false,
                        authorized_user_ids: ledger.authorized_user_ids)
      end
    end

    on AccountRenamed do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all name: event.name
    end

    on AccountClosed do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all is_closed: true
    end

    on AccountReopened do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all is_closed: false
    end

    on AccountRemoved do |event|
      Account.where(aggregate_id: event.aggregate_id).delete_all
    end

    on AccountBalanceChanged do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all balance: event.balance
    end

    on AccountCategoryAssigned do |event|
      Account.where(ledger_id: event.aggregate_id, aggregate_id: event.account_id).update_all category_id: event.category_id
    end

    def purge!
      # TODO: Get rid of this dependency
      logger.warn 'Please make sure pending transactions is purged as well since they are dependant'
      super
    end
  end
end
