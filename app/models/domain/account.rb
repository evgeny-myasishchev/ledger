class Domain::Account < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain
  include Domain::Events
  
  def create ledger_id, sequential_number, name, currency
    log.debug "Creating new account '#{name}' for ledger_id='#{ledger_id}'"
    raise_event AccountCreated.new AggregateId.new_id, ledger_id, sequential_number, name, currency.code
  end
  
  def rename new_name
    raise_event AccountRenamed.new aggregate_id, new_name
  end
  
  def close
    return unless @is_open
    raise_event AccountClosed.new aggregate_id
  end
  
  def report_income ammount, date, tag_ids = nil, comment = nil
    log.debug "Reporting #{ammount} of income for account aggregate_id='#{aggregate_id}'"
    ammount = Money.parse(ammount, @currency)
    balance = @balance + ammount.integer_ammount
    tag_ids = normalize_tag_ids tag_ids
    transaction_id = AggregateId.new_id
    raise_transaction_reported transaction_id, Transaction::IncomeTypeId, ammount.integer_ammount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end
  
  def report_expence ammount, date, tag_ids = [], comment = nil
    ammount = Money.parse(ammount, @currency)
    log.debug "Reporting #{ammount} of expence for account aggregate_id='#{aggregate_id}'"
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance - ammount.integer_ammount
    transaction_id = AggregateId.new_id
    raise_transaction_reported transaction_id, Transaction::ExpenceTypeId, ammount.integer_ammount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end

  def report_refund ammount, date, tag_ids = [], comment = nil
    ammount = Money.parse(ammount, @currency)
    log.debug "Reporting #{ammount} of refund for account aggregate_id='#{aggregate_id}'"
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance + ammount.integer_ammount
    transaction_id = AggregateId.new_id
    raise_transaction_reported transaction_id, Transaction::RefundTypeId, ammount.integer_ammount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end

  def send_transfer(receiving_account_id, ammount, date, tag_ids = [], comment = nil)
    ammount = Money.parse(ammount, @currency)
    log.debug "Sending #{ammount} of transfer. Sender aggregate_id='#{aggregate_id}'. Receiver aggregate_id='#{receiving_account_id}'"
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance - ammount.integer_ammount
    transaction_id = AggregateId.new_id
    raise_event TransferSent.new aggregate_id, transaction_id, receiving_account_id, ammount.integer_ammount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
    transaction_id
  end

  def receive_transfer(sending_account_id, sending_transaction_id, ammount, date, tag_ids = [], comment = nil)
    ammount = Money.parse(ammount, @currency)
    log.debug "Receiving #{ammount} of transfer. Sender aggregate_id='#{sending_account_id}'. Receiver aggregate_id='#{aggregate_id}'"
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance + ammount.integer_ammount
    transaction_id = AggregateId.new_id
    raise_event TransferReceived.new aggregate_id, transaction_id, sending_account_id, sending_transaction_id, ammount.integer_ammount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end
  
  def adjust_ammount transaction_id, ammount
  end
  
  def adjust_comment transaction_id, comment
    raise_event TransactionCommentAdjusted.new aggregate_id, transaction_id, comment
  end
  
  def adjust_date transaction_id, date
    raise_event TransactionDateAdjusted.new aggregate_id, transaction_id, date
  end
  
  def adjust_tags transaction_id, tag_ids
    tag_ids = [] if tag_ids.nil?
    current_tags = @transactions[transaction_id][:tag_ids]
    (tag_ids - current_tags).each { |tag_id|
      raise_event TransactionTagged.new aggregate_id, transaction_id, tag_id
    }
    (current_tags - tag_ids).each { |tag_id|
      raise_event TransactionUntagged.new aggregate_id, transaction_id, tag_id
    }
  end

  private def raise_transaction_reported transaction_id, type_id, integer_ammount, date, tag_ids, comment
    raise_event TransactionReported.new aggregate_id, transaction_id, type_id,integer_ammount, date, tag_ids, comment
  end

  private def raise_balance_changed transaction_id, balance
    raise_event AccountBalanceChanged.new aggregate_id, transaction_id, balance
  end
  
  private def normalize_tag_ids tag_ids
    return [] if tag_ids.nil?
    return tag_ids if tag_ids.is_a? Enumerable
    return [tag_ids]
  end
  
  on AccountCreated do |event|
    @aggregate_id = event.aggregate_id
    @is_open = true
    @currency = Currency[event.currency_code]
    @balance = 0
    @transactions = {}
  end
  
  on AccountRenamed do |event|
    
  end
  
  on AccountClosed do |event|
    @is_open = false
  end
  
  on TransactionReported do |event|
    @transactions[event.transaction_id] = {
      tag_ids: event.tag_ids
    }
  end

  on TransferSent do |event|
    
  end

  on TransferReceived do |event|
    
  end
  
  on TransactionTagged do |event|
    @transactions[event.transaction_id][:tag_ids] << event.tag_id
  end
  
  on TransactionUntagged do |event|
    @transactions[event.transaction_id][:tag_ids].delete(event.tag_id)
  end
  
  on AccountBalanceChanged do |event|
    @balance = event.balance
  end
  
  on TransactionCommentAdjusted do |event|
  end  
  
  on TransactionDateAdjusted do |event|
  end
end