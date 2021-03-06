class Projections::Tag < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include UserAuthorizable
  
  def self.get_user_tags(user)
    # TODO: Limit attributes
    Tag.where('authorized_user_ids LIKE ?', "%{#{user.id}}%")
  end

  projection do
    on LedgerShared do |event|
      Tag.where(ledger_id: event.aggregate_id).each { |a|
        a.authorize_user event.user_id
        a.save!
      }
    end

    on TagCreated do |event|
      unless Tag.exists? ledger_id: event.aggregate_id, tag_id: event.tag_id
        ledger = Ledger.find_by_aggregate_id event.aggregate_id
        Tag.create! ledger_id: event.aggregate_id, 
          tag_id: event.tag_id,
          name: event.name,
          authorized_user_ids: ledger.authorized_user_ids
      end
    end

    on TagRenamed do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).update_all(name: event.name)
    end
    
    on TagRemoved do |event|
      Tag.where(ledger_id: event.aggregate_id, tag_id: event.tag_id).delete_all
    end
  end
end
