class Domain::PendingTransaction < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain::Events
  
  attr_reader :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  attr_reader :is_approved, :is_rejected
  
  def report user, transaction_id, amount, date: DateTime.now, tag_ids: nil, comment: nil, account_id: nil, type_id: nil
    type_id = type_id.blank? ? Domain::Transaction::ExpenseTypeId : type_id
    Log.debug "Reporting new pending transaction id=#{transaction_id} by user: #{user.id}"
    raise ArgumentError.new 'transaction_id can not be empty.' if transaction_id.blank?
    raise ArgumentError.new 'amount can not be empty.' if amount.blank?
    raise ArgumentError.new 'date can not be empty.' if date.blank?
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
    raise Errors::DomainError.new 'account_id is empty.' if account_id.blank?
    raise Errors::DomainError.new "account is wrong. Expected account='#{account_id}' but was account='#{account.aggregate_id}'." unless account.aggregate_id == account_id
    raise Errors::DomainError.new "pending transaction id=(#{aggregate_id}) has already been approved." if @is_approved
    if type_id == Domain::Transaction::IncomeTypeId
      account.report_income aggregate_id, amount, date, tag_ids, comment
    elsif type_id == Domain::Transaction::ExpenseTypeId
      account.report_expense aggregate_id, amount, date, tag_ids, comment
    elsif type_id == Domain::Transaction::RefundTypeId
      account.report_refund aggregate_id, amount, date, tag_ids, comment
    else
      raise Errors::DomainError.new "unknown type: #{type_id}"
    end
    raise_event PendingTransactionApproved.new aggregate_id
  end
  
  def approve_transfer sending_account, receiving_account, ammount_received
    
  end
  
  def reject
    return if @is_rejected
    Log.debug "Rejecting transaction id=#{aggregate_id}"
    raise_event PendingTransactionRejected.new aggregate_id
  end
  
  on PendingTransactionReported do |event|
    @is_approved = false
    @aggregate_id = event.aggregate_id
    @user_id = event.user_id
    
    update_attributes event
  end
  
  on PendingTransactionAdjusted do |event|
    update_attributes event
  end
  
  on PendingTransactionApproved do |event|
    @is_approved = true
  end
  
  on PendingTransactionRejected do |event|
    @is_rejected = true
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