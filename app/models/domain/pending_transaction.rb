class Domain::PendingTransaction < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain::Events
  
  attr_reader :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  
  def report user, transaction_id, amount, date: nil, tag_ids: nil, comment: nil, account_id: nil, type_id: Transaction::ExpenceTypeId
    Log.debug "Reporting new pending transaction id=#{transaction_id} by user: #{user.id}"
    raise_event PendingTransactionReported.new transaction_id, user.id, amount, date, tag_ids, comment, account_id, type_id
  end
  
  def adjust amount: nil, date: nil, tag_ids: nil, comment: nil, account_id: nil, type_id: nil
    Log.debug "Adjusting transaction id=#{aggregate_id}"
    event = PendingTransactionAdjusted.new aggregate_id,
      amount || self.amount,
      date || self.date,
      tag_ids || self.tag_ids,
      comment || self.comment,
      account_id || self.account_id,
      type_id || self.type_id
    
    raise_event(event) unless (self.amount == event.amount && 
      self.date == event.date && 
      self.tag_ids == event.tag_ids &&
      self.comment == event.comment &&
      self.account_id == event.account_id &&
      self.type_id == event.type_id)
  end
  
  def approve account
    Log.debug "Approving transaction id=#{aggregate_id}"
  end
  
  on PendingTransactionReported do |event|
    @aggregate_id = event.aggregate_id
    @user_id = event.user_id
    
    update_attributes event
  end
  
  on PendingTransactionAdjusted do |event|
    update_attributes event
  end
  
  private def update_attributes event
    @amount = event.amount
    @date = event.date
    @tag_ids = event.tag_ids
    @comment = event.comment
    @account_id = event.account_id
    @type_id = event.type_id
  end
end