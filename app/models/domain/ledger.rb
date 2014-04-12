class Domain::Ledger < CommonDomain::Aggregate
  include CommonDomain::Infrastructure
  include Domain::Events
  
  def create owner_user_id, name
    raise_event LedgerCreated.new AggregateId.new_id, owner_user_id, name
  end
  
  def rename name
    raise_event LedgerRenamed.new aggregate_id, name
  end
  
  def share user_id
    return if @shared_with.include?(user_id)
    raise_event LedgerShared.new aggregate_id, user_id
  end
  
  def add_account name, currency
  end
  
  def create_tag name
  end
  
  def rename_tag tag_id, name
  end
  
  def remove_tag tag_id
  end
  
  on LedgerCreated do |event|
    @aggregate_id = event.aggregate_id
    @name = event.name
    @shared_with = Set.new
  end
  
  on LedgerRenamed do |event|
    @name = event.name
  end
  
  on LedgerShared do |event|
    @shared_with << event.user_id
  end
end