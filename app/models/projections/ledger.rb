class Projections::Ledger < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  serialize :shared_with_user_ids, Set
  
  projection do
    on LedgerCreated do |event|
      Ledger.create!(aggregate_id: event.aggregate_id, owner_user_id: event.user_id, name: event.name) unless
        Ledger.exists?(aggregate_id: event.aggregate_id)
    end
    
    on LedgerRenamed do |event|
      Ledger.where(aggregate_id: event.aggregate_id).update_all name: event.name
    end
    
    on LedgerShared do |event|
      ledger = Ledger.find_by_aggregate_id event.aggregate_id
      ledger.shared_with_user_ids.add event.user_id
      ledger.save!
    end
  end
  
  
  #   projection do
  #     on Events::EmployeeCreated do |event|
  #       Employee.create! employee_id: event.aggregate_id, name: event.name
  #     end
  #   
  #     on Events::EmployeeRenamed do |event|
  #       rec = Employee.find_by(employee_id: event.aggregate_id)
  #       rec.name = event.name
  #       rec.save!
  #     end
  #   
  #     on Events::EmployeeRemoved do |event|
  #       Employee.where(employee_id: event.aggregate_id).delete_all
  #     end
  #   end
  
end
