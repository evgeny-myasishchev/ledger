class Domain::Account < CommonDomain::Aggregate
  def create name, currency
  end
  
  def rename name
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
end