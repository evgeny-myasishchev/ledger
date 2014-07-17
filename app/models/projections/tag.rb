class Projections::Tag < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  projection do
    on TagCreated do |event|
      Tag.create! ledger_id: event.aggregate_id, tag_id: event.tag_id, name: event.name
    end
    
    on TagRenamed do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).update_all(name: event.name)
    end
    
    on TagRemoved do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).delete_all
    end
  end
end
