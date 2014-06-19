class Domain::Account < CommonDomain::Aggregate
  include CommonDomain::Infrastructure
  include Domain
  include Domain::Events
  
  def create ledger_id, name, currency
    raise_event AccountCreated.new AggregateId.new_id, ledger_id, name, currency.code
  end
  
  def rename new_name
    raise_event AccountRenamed.new aggregate_id, new_name
  end
  
  def close
    return unless @is_open
    raise_event AccountClosed.new aggregate_id
  end
  
  def report_income ammount, date, tag_ids = nil, comment = nil
    ammount = Money.parse(ammount, @currency)
    balance = @balance + ammount.integer_ammount
    raise_event TransactionReported.new aggregate_id, AggregateId.new_id, Transaction::IncomeTypeId, ammount.integer_ammount, balance, date, tag_ids, comment
  end
  
  def report_expence ammount, date, tag_ids = nil, comment = nil
    ammount = Money.parse(ammount, @currency)
    balance = @balance - ammount.integer_ammount
    raise_event TransactionReported.new aggregate_id, AggregateId.new_id, Transaction::ExpenceTypeId, ammount.integer_ammount, balance, date, tag_ids, comment
  end
  
  def adjust_ammount transaction_id, ammount
  end
  
  def adjust_comment transaction_id, comment
  end
  
  def add_tag transaction_id, tag
  end
  
  def remove_tag transaction_id, tag
  end
  
  on AccountCreated do |event|
    @aggregate_id = event.aggregate_id
    @is_open = true
    @currency = Currency[event.currency_code]
    @balance = 0
  end
  
  on AccountRenamed do |event|
    
  end
  
  on AccountClosed do |event|
    @is_open = false
  end
  
  on TransactionReported do |event|
    @balance = event.balance
  end
end