class Domain::Account < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain
  include Domain::Events
  
  AccountId = Struct.new(:aggregate_id, :sequential_number)
  InitialData = Struct.new(:name, :initial_balance, :currency, :unit)

  attr_reader :ledger_id, :sequential_number, :name, :currency, :unit,
    :is_open, :is_removed, :balance, :transactions
  
  def create ledger_id, account_id, initial_data
    initial_balance = Money.parse(initial_data.initial_balance, initial_data.currency)
    unit = initial_data.unit || initial_data.currency.unit
    raise_event AccountCreated.new account_id.aggregate_id, ledger_id, account_id.sequential_number, 
      initial_data.name, initial_balance.integer_amount, initial_data.currency.code, unit
  end
  
  def rename name
    return if @name == name
    log.debug "Renaming account aggregate_id='#{aggregate_id}. New name: #{name}'"
    raise_event AccountRenamed.new aggregate_id, name
  end
  
  def set_unit unit
    return if @unit == unit
    log.debug "Assigning account unit aggregate_id='#{aggregate_id}. New unit: #{unit}'"
    raise_event AccountUnitAdjusted.new aggregate_id, unit
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
  
  def report_income transaction_id, amount, date, tag_ids = nil, comment = nil
    log.debug "Reporting #{amount} of income for account aggregate_id='#{aggregate_id}'"
    ensure_transaction_id_unique! transaction_id
    amount = Money.parse(amount, @currency)
    balance = @balance + amount.integer_amount
    tag_ids = normalize_tag_ids tag_ids
    raise_transaction_reported transaction_id, Transaction::IncomeTypeId, amount.integer_amount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end
  
  def report_expence transaction_id, amount, date, tag_ids = [], comment = nil
    amount = Money.parse(amount, @currency)
    log.debug "Reporting #{amount} of expence for account aggregate_id='#{aggregate_id}'"
    ensure_transaction_id_unique! transaction_id
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance - amount.integer_amount
    raise_transaction_reported transaction_id, Transaction::ExpenceTypeId, amount.integer_amount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end

  def report_refund transaction_id, amount, date, tag_ids = [], comment = nil
    amount = Money.parse(amount, @currency)
    log.debug "Reporting #{amount} of refund for account aggregate_id='#{aggregate_id}'"
    ensure_transaction_id_unique! transaction_id
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance + amount.integer_amount
    raise_transaction_reported transaction_id, Transaction::RefundTypeId, amount.integer_amount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end

  def send_transfer(transaction_id, receiving_account_id, amount, date, tag_ids = [], comment = nil)
    amount = Money.parse(amount, @currency)
    log.debug "Sending #{amount} of transfer. Sender aggregate_id='#{aggregate_id}'. Receiver aggregate_id='#{receiving_account_id}'"
    ensure_transaction_id_unique! transaction_id
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance - amount.integer_amount
    raise_event TransferSent.new aggregate_id, transaction_id, receiving_account_id, amount.integer_amount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
    transaction_id
  end

  def receive_transfer(transaction_id, sending_account_id, sending_transaction_id, amount, date, tag_ids = [], comment = nil)
    amount = Money.parse(amount, @currency)
    log.debug "Receiving #{amount} of transfer. Sender aggregate_id='#{sending_account_id}'. Receiver aggregate_id='#{aggregate_id}'"
    ensure_transaction_id_unique! transaction_id
    tag_ids = normalize_tag_ids tag_ids
    balance = @balance + amount.integer_amount
    raise_event TransferReceived.new aggregate_id, transaction_id, sending_account_id, sending_transaction_id, amount.integer_amount, date, tag_ids, comment
    raise_balance_changed transaction_id, balance
  end
  
  def adjust_amount transaction_id, amount
    new_amount = Money.parse(amount, @currency)
    transaction = get_transaction! transaction_id
    original_integer_amount = transaction[:amount]
    log.debug "Adjusting amount of transaction_id='#{transaction_id}' to #{new_amount} of account aggregate_id='#{aggregate_id}'."
    if(original_integer_amount == new_amount.integer_amount)
      log.debug "The amount is the same. Further processing skipped."
      return 
    end
    new_balance = @balance
    if (transaction[:type_id] == Transaction::IncomeTypeId || transaction[:type_id] == Transaction::RefundTypeId)
      new_balance = @balance - original_integer_amount + new_amount.integer_amount
    elsif transaction[:type_id] == Transaction::ExpenceTypeId
      new_balance = @balance + original_integer_amount - new_amount.integer_amount
    else
      raise "Unknown transaction type: #{transaction[:type_id]}"
    end
    log.debug "Original balance was '#{@balance}', new balance is '#{new_balance}' for account aggregate_id='#{aggregate_id}'"
    raise_event TransactionAmountAdjusted.new aggregate_id, transaction_id, new_amount.integer_amount
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
    amount = transaction[:amount]
    new_balance = @balance
    if (transaction[:type_id] == Transaction::IncomeTypeId || transaction[:type_id] == Transaction::RefundTypeId)
      new_balance = @balance - amount
    elsif transaction[:type_id] == Transaction::ExpenceTypeId
      new_balance = @balance + amount
    else
      raise "Unknown transaction type: #{transaction[:type_id]}"
    end
    log.debug "Original balance was '#{@balance}', new balance is '#{new_balance}' for account aggregate_id='#{aggregate_id}'"
    raise_event TransactionRemoved.new aggregate_id, transaction_id
    raise_balance_changed transaction_id, new_balance
  end
  
  def move_transaction_to transaction_id, target_account
    transaction = get_transaction!(transaction_id)
    log.debug "Moving transaction id='#{transaction_id}' from account id='#{aggregate_id}' to account id=#{target_account.aggregate_id}"
    remove_transaction transaction_id
    target_account.accept_moved_transaction_from self, transaction
    raise_event TransactionMovedTo.new aggregate_id, target_account.aggregate_id, transaction_id
  end
  
  def accept_moved_transaction_from sending_account, transaction
    # report[income|expence|refund|send_transfer|receive_transfer]
    # raise_event TransactionMovedFrom.new aggregate_id, target_account.aggregate_id, transaction[:id]
  end
  
  def get_snapshot
    {
      ledger_id: ledger_id,
      sequential_number: sequential_number,
      name: name,
      currency_code: currency.code,
      unit: unit,
      is_open: is_open,
      is_removed: is_removed,
      balance: balance,
      transactions: @transactions
    }
  end
  
  def apply_snapshot(snapshot)
    @ledger_id = snapshot[:ledger_id]
    @sequential_number = snapshot[:sequential_number]
    @name = snapshot[:name]
    @currency = Currency[snapshot[:currency_code]]
    @unit = snapshot[:unit]
    @is_open = snapshot[:is_open]
    @is_removed = snapshot[:is_removed]
    @balance = snapshot[:balance]
    @transactions = snapshot[:transactions]
  end
  
  def self.add_snapshot?(aggregate)
    aggregate.applied_events_number > 10
  end

  private def raise_transaction_reported transaction_id, type_id, integer_amount, date, tag_ids, comment
    raise_event TransactionReported.new aggregate_id, transaction_id, type_id,integer_amount, date, tag_ids, comment
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
    @ledger_id = event.ledger_id
    @sequential_number = event.sequential_number
    @name = event.name
    @unit = event.unit
    @is_open = true
    @is_removed = false
    @currency = Currency[event.currency_code]
    @balance = event.initial_balance
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
    transaction = index_transaction event.transaction_id, Transaction::ExpenceTypeId, event
    transaction[:is_transfer] = true
  end

  on TransferReceived do |event|
    transaction = index_transaction event.transaction_id, Transaction::IncomeTypeId, event
    transaction[:is_transfer] = true
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
  
  on TransactionAmountAdjusted do |event|
    @transactions[event.transaction_id][:amount] = event.amount
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
  
  on TransactionMovedTo do |event|
    # No logic for now
  end
  
  private 
    def get_transaction! transaction_id
      raise "Unknown transaction '#{transaction_id}'" unless @transactions.key?(transaction_id)
      return @transactions[transaction_id]
    end
  
    def index_transaction transaction_id, type_id, event
      @transactions[transaction_id] = {
        id: transaction_id,
        type_id: type_id,
        amount: event.amount,
        tag_ids: event.tag_ids,
        date: event.date,
        comment: event.comment
      }
    end
    
    def ensure_transaction_id_unique! transaction_id
      raise ArgumentError.new("transaction_id='#{transaction_id}' is not unique.") if @transactions.key?(transaction_id)
    end
end