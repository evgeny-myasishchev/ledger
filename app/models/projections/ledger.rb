class Projections::Ledger < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  serialize :shared_with_user_ids, Set

  def authorized_user_ids
    @authorized_user_ids ||= begin
      authorized_user_ids = shared_with_user_ids.to_a
      authorized_user_ids << owner_user_id
      authorized_user_ids
    end    
  end
  
  def self.get_user_ledgers(user)
    where(owner_user_id: user.id).select(:id, :aggregate_id, :name).to_a
  end
  
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
end
