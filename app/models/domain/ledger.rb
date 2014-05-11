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
  
  def create_new_account name, currency
    account = Domain::Account.new
    account.create aggregate_id, name, currency
    raise_event AccountAddedToLedger.new aggregate_id, account.aggregate_id
    account
  end
  
  def close_account account
    raise "Account '#{account.aggregate_id}' is not from ledger '#{@name}'." unless @all_accounts.include?(account.aggregate_id)
    if @open_accounts.include?(account.aggregate_id)
      account.close
      raise_event LedgerAccountClosed.new aggregate_id, account.aggregate_id
    end
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
    @all_accounts = Set.new
    @open_accounts = Set.new
  end
  
  on LedgerRenamed do |event|
    @name = event.name
  end
  
  on LedgerShared do |event|
    @shared_with << event.user_id
  end
  
  on AccountAddedToLedger do |event|
    @all_accounts << event.account_id
    @open_accounts << event.account_id
  end
  
  on LedgerAccountClosed do |event|
    @open_accounts.delete event.account_id
  end
end