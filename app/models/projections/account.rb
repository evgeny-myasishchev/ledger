class Projections::Account < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include UserAuthorizable
  
  def self.get_user_accounts(user)
    Account.
      select(:aggregate_id, :name, :balance, :currency_code, :sequential_number, :category_id, :is_closed).
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
  
  projection do
    on LedgerShared do |event|
      Account.where(ledger_id: event.aggregate_id).each { |a|
        a.authorize_user event.user_id
        a.save!
      }
    end
    
    on AccountCreated do |event|
      unless Account.exists? aggregate_id: event.aggregate_id
        ledger = Ledger.find_by_aggregate_id event.ledger_id
        account = Account.new(aggregate_id: event.aggregate_id, 
          ledger_id: event.ledger_id, 
          sequential_number: event.sequential_number,
          owner_user_id: ledger.owner_user_id,
          name: event.name, 
          currency_code: event.currency_code,
          balance: event.initial_balance,
          is_closed: false) 
        account.set_authorized_users ledger.authorized_user_ids
        account.save!
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
  end
end
