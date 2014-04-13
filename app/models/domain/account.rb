class Domain::Account < CommonDomain::Aggregate
  include CommonDomain::Infrastructure
  include Domain::Events
  
  def create ledger_id, name, currency
    raise_event AccountCreated.new AggregateId.new_id, ledger_id, name, currency.id
  end
  
  def rename new_name
    raise_event AccountRenamed.new aggregate_id, new_name
  end
  
  def close
    return unless @is_open
    raise_event AccountClosed.new aggregate_id
  end
  
  def report_income ammount, tags, comment
  end
  
  def report_expence ammount, tags, comment
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
    @is_open = true
  end
  
  on AccountRenamed do |event|
    
  end
  
  on AccountClosed do |event|
    @is_open = false
  end
end