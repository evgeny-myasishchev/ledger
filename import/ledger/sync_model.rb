class SyncModel
  include ::Domain::Events
  include Application::Commands
  
  def initialize(context)
    @context = context
    @deferred_commands = []
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
    tags.each { |tag|
      tag = tag['tag']
      log.debug "Creating tag: #{tag}"
      dispatch LedgerCommands::ImportTagWithId.new(@ledger_id, tag_id: tag['id'], name: tag['name']), user_id: tag['user_id']
    }
  end
  
  def create_categories categories
    log.info 'Creating categories'
    @context.repository.begin_work do |work|
      ledger = work.get_by_id Domain::Ledger, @ledger_id
      categories.each { |category|
        log.debug "Creating category: #{category}"
        ledger.send :raise_event, CategoryCreated.new(ledger.aggregate_id, category['id'], category['display_order'], category['name'])
      }
    end
  end
  
  def create_accounts accounts
    log.info 'Creating accounts'
    @accounts_map = {} #key - old integer id, value - new account aggregate_id
    @context.repository.begin_work do |work|
      ledger = work.get_by_id Domain::Ledger, @ledger_id
      accounts.each { |account_data|
        account = account_data['account']
        log.debug "Creating account: #{account}"
        currency = detect_account_currency account
        unit = currency.unit && currency.unit == 'ozt' ? 'g' : nil
        new_account_id = CommonDomain::Infrastructure::AggregateId.new_id
        @accounts_map[account['id']] = new_account_id
        domain_account = ledger.create_new_account new_account_id, Domain::Account::InitialData.new(account['name'], 0, currency, unit)
        @deferred_commands << LedgerCommands::CloseAccount.new(ledger.aggregate_id, account_id: domain_account.aggregate_id) if account['is_closed']
        if account['category_id']
          @deferred_commands << LedgerCommands::SetAccountCategory.new(ledger.aggregate_id, account_id: domain_account.aggregate_id, category_id: account['category_id'])
        end
        work.add_new domain_account
      }
    end
  end
  
  
  def create_transactions account, transactions
    aggregate_id = @accounts_map[account['account']['id']]
    @context.repository.begin_work do |work|
      account = work.get_by_id Domain::Account, aggregate_id
      transactions.each { |data|
        transaction = data['transaction']
        type_id = transaction['transaction_type_id']
        spec_id = transaction['specification_id']
        tag_ids = transaction['tags'].map { |t| t['id'] }
        
        if type_id == 1 #Income
          if spec_id == 1 #Refund
            account.report_refund transaction['ammount'], DateTime.iso8601(transaction['date']), tag_ids, transaction['name']
          else
            account.report_income transaction['ammount'], DateTime.iso8601(transaction['date']), tag_ids, transaction['name']
          end
        else
          account.report_expence transaction['ammount'], DateTime.iso8601(transaction['date']), tag_ids, transaction['name']
        end
      }
    end
  end
  
  def set_account_balance account
    aggregate_id = @accounts_map[account['account']['id']]
    currency = detect_account_currency account['account']
    @context.repository.begin_work do |work|
      domain_account = work.get_by_id Domain::Account, aggregate_id
      balance = Money.parse(account['account']['balance'], currency).integer_ammount
      domain_account.send :raise_event, AccountBalanceChanged.new(aggregate_id, nil, balance)
    end
  end
  
  def finalize
    @deferred_commands.each { |command| dispatch command }
    @context.event_store.dispatcher.wait_pending
  end
  
  private 
    def log
      @log ||= LogFactory.logger 'ledger::thebablo'
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
end