class Domain::Account < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain
  include Domain::Events
  
  AccountId = Struct.new(:aggregate_id, :sequential_number)
  InitialData = Struct.new(:name, :initial_balance, :currency, :unit)
  
  def create ledger_id, account_id, initial_data
    initial_balance = Money.parse(initial_data.initial_balance, initial_data.currency)
    unit = initial_data.unit || initial_data.currency.unit
    raise_event AccountCreated.new account_id.aggregate_id, ledger_id, account_id.sequential_number, 
      initial_data.name, initial_balance.integer_ammount, initial_data.currency.code, unit
  end
  
  def rename new_name
    return if @name == new_name
    log.debug "Renaming account aggregate_id='#{aggregate_id}. New name: #{new_name}'"
    raise_event AccountRenamed.new aggregate_id, new_name
  end
  
  def set_unit new_unit
    return if @unit == new_unit
    log.debug "Assigning account unit aggregate_id='#{aggregate_id}. New unit: #{new_unit}'"
    raise_event AccountUnitAdjusted.new aggregate_id, new_unit
  end
  
  def close
    return unless @is_open
    raise_event AccountClosed.new aggregate_id
  end
  
  def reopen
    ensure_closed!
    raise_event AccountReopened.new aggregate_id
  end
  
  def remove
    ensure_closed!
    return if @is_removed
    raise_event AccountRemoved.new aggregate_id
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
    new_ammount = Money.parse(ammount, @currency)
    transaction = get_transaction! transaction_id
    original_integer_ammount = transaction[:ammount]
    log.debug "Adjusting ammount of transaction_id='#{transaction_id}' to #{new_ammount} of account aggregate_id='#{aggregate_id}'."
    if(original_integer_ammount == new_ammount.integer_ammount)
      log.debug "The ammount is the same. Further processing skipped."
      return 
    end
    new_balance = @balance
    if (transaction[:type_id] == Transaction::IncomeTypeId || transaction[:type_id] == Transaction::RefundTypeId)
      new_balance = @balance - original_integer_ammount + new_ammount.integer_ammount
    elsif transaction[:type_id] == Transaction::ExpenceTypeId
      new_balance = @balance + original_integer_ammount - new_ammount.integer_ammount
    else
      raise "Unknown transaction type: #{transaction[:type_id]}"
    end
    log.debug "Original balance was '#{@balance}', new balance is '#{new_balance}' for account aggregate_id='#{aggregate_id}'"
    raise_event TransactionAmmountAdjusted.new aggregate_id, transaction_id, new_ammount.integer_ammount
    raise_balance_changed transaction_id, new_balance
  end
  
  def adjust_comment transaction_id, comment
    return if get_transaction!(transaction_id)[:comment] == comment
    raise_event TransactionCommentAdjusted.new aggregate_id, transaction_id, comment
  end
  
  def adjust_date transaction_id, date
    return if get_transaction!(transaction_id)[:date] == date
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
  
  def remove_transaction transaction_id
    return unless @transactions.key?(transaction_id)
    log.debug "Removing transaction id='#{transaction_id}' from account aggregate_id='#{aggregate_id}'"
    transaction = @transactions[transaction_id]
    ammount = transaction[:ammount]
    new_balance = @balance
    if (transaction[:type_id] == Transaction::IncomeTypeId || transaction[:type_id] == Transaction::RefundTypeId)
      new_balance = @balance - ammount
    elsif transaction[:type_id] == Transaction::ExpenceTypeId
      new_balance = @balance + ammount
    else
      raise "Unknown transaction type: #{transaction[:type_id]}"
    end
    log.debug "Original balance was '#{@balance}', new balance is '#{new_balance}' for account aggregate_id='#{aggregate_id}'"
    raise_event TransactionRemoved.new aggregate_id, transaction_id
    raise_balance_changed transaction_id, new_balance
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
  
  def ensure_closed!
    raise "Account '#{aggregate_id}' is not closed." if @is_open
  end
  
  on AccountCreated do |event|
    @aggregate_id = event.aggregate_id
    @name = event.name
    @unit = event.unit
    @is_open = true
    @is_removed = false
    @currency = Currency[event.currency_code]
    @balance = 0
    @transactions = {}
  end
  
  on AccountRenamed do |event|
    @name = event.name
  end
  
  on AccountUnitAdjusted do |event|
    @unit = event.unit
  end
  
  on AccountClosed do |event|
    @is_open = false
  end
  
  on AccountReopened do |event|
    @is_open = true
  end
  
  on AccountRemoved do |event|
    @is_removed = true
  end
  
  on TransactionReported do |event|
    index_transaction event.transaction_id, event.type_id, event
  end

  on TransferSent do |event|
    index_transaction event.transaction_id, Transaction::ExpenceTypeId, event
  end

  on TransferReceived do |event|
    index_transaction event.transaction_id, Transaction::IncomeTypeId, event
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
  
  on TransactionAmmountAdjusted do |event|
    @transactions[event.transaction_id][:ammount] = event.ammount
  end  
  
  on TransactionCommentAdjusted do |event|
    @transactions[event.transaction_id][:comment] = event.comment
  end  
  
  on TransactionDateAdjusted do |event|
    @transactions[event.transaction_id][:date] = event.date
  end
  
  on TransactionRemoved do |event|
    @transactions.delete event.transaction_id
  end
  
  private 
    def get_transaction! transaction_id
      raise "Unknown transaction '#{transaction_id}'" unless @transactions.key?(transaction_id)
      return @transactions[transaction_id]
    end
  
    def index_transaction transaction_id, type_id, event
      @transactions[transaction_id] = {
        type_id: type_id,
        ammount: event.ammount,
        tag_ids: event.tag_ids,
        ammount: event.ammount,
        date: event.date,
        comment: event.comment
      }
    end
end