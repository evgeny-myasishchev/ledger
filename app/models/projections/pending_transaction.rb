class Projections::PendingTransaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections

  belongs_to :user

  def self.get_pending_transactions user
    where(user_id: user.id).select(:id, :transaction_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id).all
  end

  def self.get_pending_transactions_count user
    where(user_id: user.id).count
  end

  projection do
    include Loggable

    on PendingTransactionReported do |event|
      transaction = PendingTransaction.find_or_initialize_by transaction_id: event.aggregate_id
      transaction.assign_attributes(
          user_id: event.user_id,
          amount: event.amount,
          date: event.date,
          tag_ids: build_tags_string(event.tag_ids),
          comment: event.comment,
          account_id: event.account_id,
          type_id: event.type_id
      )
      PendingTransaction.transaction do
        notify_account_projection :on_pending_transaction_reported,
                                  event.account_id,
                                  event.amount,
                                  event.type_id if event.account_id
        transaction.save!
      end
    end

    on PendingTransactionAdjusted do |event|
      transaction = PendingTransaction.find_by transaction_id: event.aggregate_id
      transaction.assign_attributes(
          amount: event.amount,
          date: event.date,
          tag_ids: build_tags_string(event.tag_ids),
          comment: event.comment,
          account_id: event.account_id,
          type_id: event.type_id
      )
      PendingTransaction.transaction do
        if transaction.account_id_changed?
          notify_account_projection :on_pending_transaction_rejected,
                                    transaction.account_id_was,
                                    transaction.amount_was,
                                    transaction.type_id_was if transaction.account_id_was
          notify_account_projection :on_pending_transaction_reported,
                                    transaction.account_id,
                                    transaction.amount,
                                    transaction.type_id if transaction.account_id
        elsif transaction.account_id
          notify_account_projection :on_pending_transaction_adjusted,
                                    transaction.account_id,
                                    transaction.amount_was,
                                    transaction.type_id_was,
                                    transaction.amount,
                                    transaction.type_id
        end
        transaction.save!
      end
    end

    on PendingTransactionApproved do |event|
      PendingTransaction.delete_all transaction_id: event.aggregate_id
    end

    on PendingTransactionRejected do |event|
      PendingTransaction.delete_all transaction_id: event.aggregate_id
    end

    private

    def build_tags_string(tag_ids)
      tag_ids.blank? ? nil : tag_ids.map { |id| "{#{id}}" }.join(',')
    end

    def notify_account_projection(action, account_id, *args)
      raise ArgumentError, "account_id can not be null" if account_id.nil?
      logger.debug "Notifying account: '#{account_id}'. Action: #{action}"
      account = Projections::Account.find_by! aggregate_id: account_id
      account.send(action, *args)
      account.save!
    end
  end
end
