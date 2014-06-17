class Projections::Account < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  projection do
    on AccountCreated do |event|
      Account.create!(aggregate_id: event.aggregate_id, 
        ledger_id: event.ledger_id, 
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
