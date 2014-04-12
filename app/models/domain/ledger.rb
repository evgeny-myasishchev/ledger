class Domain::Ledger < CommonDomain::Aggregate
  def create owner_user_id, name
  end
  
  def rename name
  end
  
  def share user_id
  end
  
  def add_account name, currency
  end
end