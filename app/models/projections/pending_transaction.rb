class Projections::PendingTransaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  def self.get_pending_transactions user
    where(user_id: user.id).select(:id, :transaction_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id).all
  end
  
  def self.get_pending_transactions_count user
    where(user_id: user.id).count
  end
  
  projection do
    on PendingTransactionReported do |event|
      t = PendingTransaction.find_or_initialize_by transaction_id: event.aggregate_id
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
      PendingTransaction.where(transaction_id: event.aggregate_id).update_all(
        amount: event.amount,
        date: event.date,
        tag_ids: build_tags_string(event.tag_ids),
        comment: event.comment,
        account_id: event.account_id,
        type_id: event.type_id
      )
    end
    
    on PendingTransactionApproved do |event|
      PendingTransaction.delete_all transaction_id: event.aggregate_id
    end
    
    on PendingTransactionRejected do |event|
      PendingTransaction.delete_all transaction_id: event.aggregate_id
    end
    
    private def build_tags_string(tag_ids)
      tag_ids.nil? ? nil : tag_ids.map { |id| "{#{id}}" }.join(',')
    end
  end
end
