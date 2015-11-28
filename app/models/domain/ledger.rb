class Domain::Ledger < CommonDomain::Aggregate
  include Loggable
  include CommonDomain
  include Domain::Events
  
  def create owner_user_id, name, default_currency
    logger.debug "Creating ledger: #{name}"
    raise_event LedgerCreated.new Aggregate.new_id, owner_user_id, name, default_currency.code
  end
  
  def rename name
    logger.debug "Renaming account '#{aggregate_id}'. New name: #{name}"
    raise_event LedgerRenamed.new aggregate_id, name
  end
  
  def share user
    return if @shared_with.include?(user.id)
    logger.debug "Sharing account '#{aggregate_id}' with user id=#{user.id}"
    raise_event LedgerShared.new aggregate_id, user.id
  end
  
  def create_new_account id, initial_data
    raise ArgumentError.new "account_id='#{id}' is not unique" if @all_accounts.include?(id)
    logger.debug "Creating new account ledger_id='#{aggregate_id}' id='#{id}' '#{initial_data}'"
    account = Domain::Account.new
    account.create aggregate_id, Domain::Account::AccountId.new(id, @account_sequential_number), initial_data
    raise_event AccountAddedToLedger.new aggregate_id, account.aggregate_id
    account
  end
  
  def set_account_category account, category_id
    logger.debug "Assigning account id='#{account.aggregate_id}' to category '#{category_id}'"
    ensure_known! account
    raise "Category id='#{category_id}' is not from ledger '#{@name}'." unless @known_categories.include?(category_id)
    raise_event AccountCategoryAssigned.new aggregate_id, account.aggregate_id, category_id unless 
      @all_accounts[account.aggregate_id][:category_id] == category_id
  end
  
  def close_account account
    logger.debug "Closing account id='#{account.aggregate_id}'"
    ensure_known! account
    if @open_accounts.include?(account.aggregate_id)
      account.close
      raise_event LedgerAccountClosed.new aggregate_id, account.aggregate_id
    end
  end
  
  def reopen_account account
    logger.debug "Reopening account id='#{account.aggregate_id}'"
    ensure_known! account
    ensure_closed! account
    account.reopen
    raise_event LedgerAccountReopened.new aggregate_id, account.aggregate_id
  end
  
  def remove_account account
    logger.debug "Removing account id='#{account.aggregate_id}'"
    ensure_known! account
    ensure_closed! account
    account.remove
    raise_event LedgerAccountRemoved.new aggregate_id, account.aggregate_id
  end
  
  def create_tag name
    tag_id = @last_tag_id + 1
    logger.debug "Creating tag '#{name}' tag_id='#{tag_id}'"
    raise_event TagCreated.new aggregate_id, tag_id, name
    tag_id
  end
  
  def import_tag_with_id tag_id, name
    logger.debug "Importing tag '#{name}' with tag_id='#{tag_id}'"
    raise_event TagCreated.new aggregate_id, tag_id, name
  end
  
  def rename_tag tag_id, name
    logger.debug "Renaming the tag with tag_id='#{tag_id}' to '#{name}"
    raise_event TagRenamed.new aggregate_id, tag_id, name
  end
  
  def remove_tag tag_id
    logger.debug "Renaming the tag with tag_id='#{tag_id}'"
    raise_event TagRemoved.new aggregate_id, tag_id
  end
    
  def create_category name
    category_id = @last_category_id + 1
    logger.debug "Creating category '#{name}' category_id='#{category_id}'"
    raise_event CategoryCreated.new aggregate_id, category_id, @max_category_display_order + 1, name
    category_id
  end
      
  def import_category category_id, display_order, name
    logger.debug "Importing category '#{name}', category_id='#{category_id}', display_order='#{display_order}"
    raise_event CategoryCreated.new aggregate_id, category_id, display_order, name
  end
  
  def rename_category category_id, name
    logger.debug "Renaming the category with category_id='#{category_id}' to '#{name}"
    raise_event CategoryRenamed.new aggregate_id, category_id, name
  end
  
  def remove_category category_id
    logger.debug "Renaming the category with category_id='#{category_id}'"
    raise_event CategoryRemoved.new aggregate_id, category_id
  end
  
  private def ensure_known! account
    raise "Account '#{account.aggregate_id}' is not from ledger '#{@name}'." unless @all_accounts.include?(account.aggregate_id)
  end
  
  private def ensure_closed! account
    raise "Account '#{account.aggregate_id}' is not closed." if @open_accounts.include?(account.aggregate_id)
  end
  
  on LedgerCreated do |event|
    @last_tag_id = 0
    @last_category_id = 0
    @aggregate_id = event.aggregate_id
    @name = event.name
    @shared_with = Set.new
    @all_accounts = Hash.new
    @open_accounts = Set.new
    @known_categories = Set.new
    @account_sequential_number = 1
    @max_category_display_order = 0
  end
  
  on LedgerRenamed do |event|
    @name = event.name
  end
  
  on LedgerShared do |event|
    @shared_with << event.user_id
  end
  
  on AccountAddedToLedger do |event|
    @all_accounts[event.account_id] = {}
    @open_accounts << event.account_id
    @account_sequential_number += 1
  end
  
  on LedgerAccountClosed do |event|
    @open_accounts.delete event.account_id
  end
  
  on LedgerAccountReopened do |event|
    @open_accounts << event.account_id
  end
  
  on LedgerAccountRemoved do |event|
    @open_accounts.delete event.account_id
    @all_accounts.delete event.account_id
  end
  
  on TagCreated do |event|
    @last_tag_id = event.tag_id if event.tag_id > @last_tag_id
  end
  
  on TagRenamed do |event|
    
  end
  
  on TagRemoved do |event|
    
  end
  
  on CategoryCreated do |event|
    @last_category_id = event.category_id if event.category_id > @last_category_id
    @known_categories << event.category_id
    @max_category_display_order = event.display_order if event.display_order > @max_category_display_order
  end
  
  on CategoryRenamed do |event|
    
  end
  
  on CategoryRemoved do |event|
    @known_categories.delete event.category_id
  end
  
  on AccountCategoryAssigned do |event|
    @all_accounts[event.account_id][:category_id] = event.category_id
  end
end