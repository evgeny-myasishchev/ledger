class Projections::Account < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  def self.get_user_accounts(user)
    
  end
  
  def authorize_user(user_id)
    authorized_user_ids_will_change!
    authorized_user_ids << ',' unless authorized_user_ids.empty?
    authorized_user_ids << '{' 
    authorized_user_ids << user_id.to_s
    authorized_user_ids << '}'
  end
  
  projection do
    on LedgerShared do |event|
      Account.where(ledger_id: event.aggregate_id).each { |a|
        a.authorize_user event.user_id
        a.save!
      }
    end
    
    on AccountCreated do |event|
      ledger = Ledger.find_by_aggregate_id event.ledger_id
      authorized_user_ids = ledger.shared_with_user_ids
      authorized_user_ids.add ledger.owner_user_id
      Account.create!(aggregate_id: event.aggregate_id, 
        ledger_id: event.ledger_id, 
        owner_user_id: ledger.owner_user_id,
        authorized_user_ids: authorized_user_ids.map { |id| "{#{id}}" }.join(','),
        name: event.name, 
        currency_code: event.currency_code, 
        balance: 0,
        is_closed: false) unless Account.exists? aggregate_id: event.aggregate_id
    end
    
    on AccountRenamed do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all name: event.name
    end
    
    on AccountClosed do |event|
      Account.where(aggregate_id: event.aggregate_id).update_all is_closed: true
    end
  end
end
