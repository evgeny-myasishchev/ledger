class SyncModel
  include ::Domain::Events
  include Application::Commands
  
  def initialize(context)
    @context = context
    @deferred_commands = []
    activate_wal_for_sqlite @context.event_store_database_config
    activate_wal_for_sqlite @context.read_store_database_config
  end
  
  def do_initial_cleanup
    log.debug 'Doing existing data clenup...'
    @context.event_store.purge
    @context.projections.for_each { |projection| projection.cleanup! }
  end
  
  def setup_users
    log.info 'Creating users...'
    @user_2 = User.create_with(id: 2, password: 'password').find_or_create_by! email: 'evgeny.myasishchev@gmail.com'
    @user_4 = User.create_with(id: 4, password: 'password').find_or_create_by! email: 'makova.nata@gmail.com'
  end
  
  def create_ledger
    log.info 'Creating ledger for the user'
    @ledger_id = @context.repository.begin_work do |work|
      l = work.add_new Domain::Ledger.new.create @user_2.id, 'Family', Currency['UAH']
      l.aggregate_id
    end
  end
  
  def create_tags tags
    log.info 'Creating tags'
    pause_dispatching
    tags.each { |tag|
      tag = tag['tag']
      log.debug "Creating tag: #{tag}"
      dispatch LedgerCommands::ImportTagWithId.new(@ledger_id, tag_id: tag['id'], name: tag['name']), user_id: tag['user_id']
    }
    resume_dispatching_and_wait
  end
  
  def create_categories categories
    log.info 'Creating categories'
    pause_dispatching
    categories.each { |category|
      log.debug "Creating category: #{category}"
      dispatch LedgerCommands::ImportCategory.new(@ledger_id, category_id: category['id'], 
        display_order: category['display_order'], name: category['name']), user_id: category['user_id']
    }
    resume_dispatching_and_wait
  end
  
  def create_accounts accounts
    log.info 'Creating accounts'
    pause_dispatching
    @accounts_map = {} #key - old integer id, value - new account aggregate_id
    accounts.each { |account_data|
      account = account_data['account']
      log.debug "Creating account: #{account}"
      currency = detect_account_currency account
      unit = currency.unit && currency.unit == 'ozt' ? 'g' : nil
      new_account_id = CommonDomain::Infrastructure::AggregateId.new_id
      @accounts_map[account['id']] = new_account_id
      
      dispatch LedgerCommands::CreateNewAccount.new(@ledger_id, account_id: new_account_id,
        name: account['name'], initial_balance: 0, currency_code: currency.code, unit: unit), user_id: account['user_id']
      if account['is_closed']
        dispatch LedgerCommands::CloseAccount.new(@ledger_id, account_id: new_account_id), user_id: account['user_id']
      end
      if account['category_id']
        dispatch LedgerCommands::SetAccountCategory.new(@ledger_id, account_id: new_account_id, category_id: account['category_id']), user_id: account['user_id']
      end
    }
    resume_dispatching_and_wait
  end
  
  
  def create_transactions account, transactions
    aggregate_id = @accounts_map[account['account']['id']]
    pause_dispatching
    transactions.each { |data|
      transaction = data['transaction']
      type_id = transaction['transaction_type_id']
      spec_id = transaction['specification_id']
      tag_ids = transaction['tags'].map { |t| t['id'] }
      
      cmd = nil
      if type_id == 1 #Income
        if spec_id == 1 #Refund
          cmd = AccountCommands::ReportRefund.new aggregate_id,
           amount: transaction['ammount'], 
           date: DateTime.iso8601(transaction['date']), 
           tag_ids: tag_ids,
           comment: transaction['name']
        else
          cmd = AccountCommands::ReportIncome.new aggregate_id,
           amount: transaction['ammount'], 
           date: DateTime.iso8601(transaction['date']), 
           tag_ids: tag_ids,
           comment: transaction['name']
        end
      else
        cmd = AccountCommands::ReportExpence.new aggregate_id,
         amount: transaction['ammount'], 
         date: DateTime.iso8601(transaction['date']), 
         tag_ids: tag_ids,
         comment: transaction['name']
      end
      dispatch cmd, user_id: transaction['user_id']
    }
    resume_dispatching_and_wait
  end
  
  def set_account_balance account
    aggregate_id = @accounts_map[account['account']['id']]
    currency = detect_account_currency account['account']
    @context.repository.begin_work do |work|
      domain_account = work.get_by_id Domain::Account, aggregate_id
      balance = Money.parse(account['account']['balance'], currency).integer_amount
      domain_account.send :raise_event, AccountBalanceChanged.new(aggregate_id, nil, balance)
    end
  end
  
  def finalize
    @deferred_commands.each { |command| dispatch command }
    @context.event_store.dispatcher.wait_pending
  end
  
  private 
    def pause_dispatching
      @context.event_store.dispatcher.stop
    end
  
    def resume_dispatching_and_wait
      ActiveRecord::Base.establish_connection
      @context.event_store.dispatcher.restart
      @context.event_store.dispatcher.wait_pending
    end
  
    def log
      @log ||= LogFactory.logger 'ledger::booker-import'
    end
    
    def dispatch command, user_id: @user_2.id
      dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user_id, '127.0.0.1'
      @context.command_dispatch_middleware.call command, dispatch_context
    end
    
    def detect_account_currency account
      currency_code = account['currency']['name']
      currency_code = 'XAU' if currency_code == 'GOLD'
      currency_code = 'XXX' if currency_code == 'Fuel'
      Currency[currency_code]
    end
    
    def activate_wal_for_sqlite config
      if config['adapter'] == 'sqlite'
        connection = Sequel.connect config
        log.info "Activating WAL mode for: #{config}"
        connection.loggers << log
        connection.execute 'PRAGMA journal_mode=WAL;'
      end
    end
end