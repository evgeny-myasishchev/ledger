class Projections::Tag < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include UserAuthorizable
  
  projection do
    on TagCreated do |event|
      ledger = Ledger.find_by_aggregate_id event.aggregate_id
      tag = Tag.new ledger_id: event.aggregate_id, tag_id: event.tag_id, name: event.name
      tag.set_authorized_users ledger.authorized_user_ids
      tag.save!
    end
    
    on TagRenamed do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).update_all(name: event.name)
    end
    
    on TagRemoved do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).delete_all
    end
  end
end
