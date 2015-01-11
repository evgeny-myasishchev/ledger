class Projections::PendingTransaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  def self.get_pending_transactions user
    where(user_id: user.id).all
  end
  
  projection do
    on PendingTransactionReported do |event|
      t = PendingTransaction.find_or_initialize_by aggregate_id: event.aggregate_id
      t.update_attributes!(
        user_id: event.user_id,
        amount: event.amount,
        date: event.date,
        tag_ids: build_tags_string(event.tag_ids),
        comment: event.comment,
        account_id: event.account_id,
        type_id: event.type_id
      )
    end
    
    on PendingTransactionAdjusted do |event|
      PendingTransaction.where(aggregate_id: event.aggregate_id).update_all(
        amount: event.amount,
        date: event.date,
        tag_ids: build_tags_string(event.tag_ids),
        comment: event.comment,
        account_id: event.account_id,
        type_id: event.type_id
      )
    end
    
    on PendingTransactionApproved do |event|
      PendingTransaction.delete_all aggregate_id: event.aggregate_id
    end
    
    private def build_tags_string(tag_ids)
      tag_ids.nil? ? nil : tag_ids.map { |id| "{#{id}}" }.join(',')
    end
  end
end
