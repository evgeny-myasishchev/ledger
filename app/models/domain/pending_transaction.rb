class Domain::PendingTransaction < CommonDomain::Aggregate
  include Loggable
  include CommonDomain
  include Domain::Events

  attr_reader :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  attr_reader :is_approved, :is_rejected

  def report(user, transaction_id, amount,
             date: DateTime.now, tag_ids: nil, comment: nil, account_id: nil, type_id: nil)
    type_id = type_id.blank? ? Domain::Transaction::ExpenseTypeId : type_id
    logger.debug "Reporting new pending transaction id=#{transaction_id} by user: #{user.id}"
    raise ArgumentError, 'transaction_id can not be empty.' if transaction_id.blank?
    raise ArgumentError, 'amount can not be empty.' if amount.blank?
    raise ArgumentError, 'date can not be empty.' if date.blank?
    raise_event PendingTransactionReported.new(transaction_id, user.id, amount, date, tag_ids, comment, account_id, type_id)
  end

  def adjust(amount: nil, date: nil, tag_ids: nil, comment: nil, account_id: nil, type_id: nil)
    logger.debug "Adjusting pending transaction id=#{aggregate_id}"
    ensure_not_approved!
    ensure_not_rejected!
    event = PendingTransactionAdjusted.new(aggregate_id,
                                           amount || self.amount,
                                           date || self.date,
                                           tag_ids || self.tag_ids,
                                           comment || self.comment,
                                           account_id || self.account_id,
                                           type_id || self.type_id)

    raise_event(event) unless self.amount == event.amount &&
                              self.date == event.date &&
                              self.tag_ids == event.tag_ids &&
                              self.comment == event.comment &&
                              self.account_id == event.account_id &&
                              self.type_id == event.type_id
  end

  def approve(account)
    logger.debug "Approving pending transaction id=#{aggregate_id}"
    validate_account_id_presence! account_id
    ensure_account_is_same! account_id, account
    ensure_not_approved!
    ensure_not_rejected!
    if type_id == Domain::Transaction::IncomeTypeId
      account.report_income aggregate_id, amount, date, tag_ids, comment
    elsif type_id == Domain::Transaction::ExpenseTypeId
      account.report_expense aggregate_id, amount, date, tag_ids, comment
    elsif type_id == Domain::Transaction::RefundTypeId
      account.report_refund aggregate_id, amount, date, tag_ids, comment
    else
      raise Errors::DomainError, "unknown type: #{type_id}"
    end
    raise_event PendingTransactionApproved.new(aggregate_id)
  end

  def approve_transfer(account, receiving_account, amount_received)
    logger.debug "Approving pending transaction id=#{aggregate_id}"
    validate_account_id_presence! account_id
    raise Errors::DomainError, 'receiving_account is nil.' if receiving_account.blank?
    raise Errors::DomainError, 'amount_received is empty.' if amount_received.blank?
    ensure_account_is_same! account_id, account
    ensure_not_approved!
    ensure_not_rejected!
    sending_transaction_id = account.send_transfer(aggregate_id,
                                                   receiving_account.aggregate_id,
                                                   amount,
                                                   date,
                                                   tag_ids,
                                                   comment)
    receiving_account.receive_transfer(Aggregate.new_id, account.aggregate_id, sending_transaction_id,
                                       amount_received,
                                       date,
                                       tag_ids,
                                       comment)
    raise_event PendingTransactionApproved.new(aggregate_id)
  end

  def reject
    return if @is_rejected
    logger.debug "Rejecting transaction id=#{aggregate_id}"
    raise_event PendingTransactionRejected.new(aggregate_id)
  end

  def restore
    logger.info "Restoring pending transaction id=#{aggregate_id}"
    raise Errors::DomainError, 'approved transaction can not be restored' if is_approved
    unless is_rejected
      logger.info "Pending transaction id=#{aggregate_id} is not rejected. Ignoring restore request."
      return
    end
    raise_event PendingTransactionRestored.new(aggregate_id, user_id, amount, date, tag_ids, comment, account_id, type_id)
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

  on PendingTransactionApproved do |_|
    @is_approved = true
  end

  on PendingTransactionRejected do |_|
    @is_rejected = true
  end

  on PendingTransactionRestored do |_|
    @is_rejected = false
  end

  private

  def update_attributes(event)
    @amount = event.amount
    @date = event.date
    @tag_ids = event.tag_ids
    @comment = event.comment
    @account_id = event.account_id
    @type_id = event.type_id
  end

  def validate_account_id_presence!(account_id)
    raise Errors::DomainError, 'account_id is empty.' if account_id.blank?
  end

  def ensure_account_is_same!(account_id, account)
    raise Errors::DomainError,
          "account is wrong. Expected account='#{account_id}' but was account='#{account.aggregate_id}'." unless account.aggregate_id == account_id
  end

  def ensure_not_approved!
    raise Errors::DomainError, "pending transaction id=(#{aggregate_id}) has already been approved." if @is_approved
  end

  def ensure_not_rejected!
    raise Errors::DomainError, "pending transaction id=(#{aggregate_id}) has been rejected." if @is_rejected
  end
end
