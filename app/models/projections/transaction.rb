class Projections::Transaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  # Gets transfer counterpart. For sending transaction that would be the receiving and vice versa.
  def get_transfer_counterpart
    raise "Transaction '#{transaction_id}' is not involved in transfer." unless is_transfer
    
    # This ons is receving. Finding sending
    return self.class.find_by transaction_id: sending_transaction_id unless transaction_id == sending_transaction_id
    
    # This one is sending. Finding receiving
    return self.class.find_by 'sending_transaction_id = ? AND receiving_transaction_id = transaction_id', sending_transaction_id
  end
  
  def add_tag(the_id)
    wrapped_tag_id = "{#{the_id}}"
    if !self.tag_ids.nil? && self.tag_ids.include?(wrapped_tag_id)
      return
    end
    result = self.tag_ids || ""
    result << ',' unless result.blank?
    result << wrapped_tag_id
    self.tag_ids = result
  end
  
  def self.get_account_transactions(user, account_id)
    account = Account.ensure_authorized! account_id, user
    Transaction.
      where('account_id = :account_id', account_id: account.aggregate_id).
      select(:id, :transaction_id, :type_id, :ammount, :tag_ids, :comment, :date, 
        :is_transfer, :sending_account_id, :sending_transaction_id, 
        :receiving_account_id, :receiving_transaction_id).
      order(date: :desc)
  end
  
  projection do
    on TransactionReported do |event|
      t = build_transaction(event)
      t.type_id = event.type_id
      t.save!
    end
    
    on TransferSent do |event|
      t = build_transaction(event)
      t.is_transfer = true
      t.type_id = Domain::Transaction::ExpenceTypeId
      t.sending_account_id = event.aggregate_id
      t.sending_transaction_id = event.transaction_id
      t.receiving_account_id = event.receiving_account_id
      t.save!
    end
        
    on TransferReceived do |event|
      t = build_transaction(event)
      t.is_transfer = true
      t.type_id = Domain::Transaction::IncomeTypeId
      t.receiving_account_id = event.aggregate_id
      t.receiving_transaction_id = event.transaction_id
      t.sending_transaction_id = event.sending_transaction_id
      t.sending_account_id = event.sending_account_id
      t.save!
    end
    
    private def build_transaction event
      t = Transaction.new account_id: event.aggregate_id,
        transaction_id: event.transaction_id,
        ammount: event.ammount,
        comment: event.comment,
        date: event.date
      assign_tags event, t
      t
    end
    
    private def assign_tags event, transaction
      event.tag_ids.each { |tag_id| transaction.add_tag tag_id }
    end
  end
end
