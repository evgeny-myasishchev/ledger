# This file contains initialization of the dummy data that is used for development purposes

include CommonDomain::NonAtomicUnitOfWork

log = Rails.logger
@log = log
@context = Rails.application.domain_context
def repository_factory
  @context.repository_factory
end

log.info 'Loadding dummy seeds...'

log.debug 'Doing existing data clenup...'
@context.event_store.purge
@context.projections.for_each { |projection| projection.cleanup! }

log.info 'Creating user dev@domain.com'
user = User.create_with(id: 1, password: 'password').find_or_create_by! email: 'dev@domain.com'

@dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user.id, '127.0.0.1'

def dispatch command
  @context.command_dispatch_middleware.call command, @dispatch_context
end

uah = Currency['UAH']

log.info 'Creating ledger for the user'
tag_ids_by_name = {}
ledger = begin_unit_of_work({}) do |work|
  l = work.add_new Domain::Ledger.new.create user.id, 'Family', uah
  tag_ids_by_name['food'] = l.create_tag 'Food'
  tag_ids_by_name['lunch'] = l.create_tag 'Lunch'
  tag_ids_by_name['entertainment'] = l.create_tag 'Entertainment'
  tag_ids_by_name['car'] = l.create_tag 'Car'
  tag_ids_by_name['gas'] = l.create_tag 'Gas'
  tag_ids_by_name['active income'] = l.create_tag 'Active Income'
  tag_ids_by_name['passive income'] = l.create_tag 'Passive Income'
  tag_ids_by_name['deposits'] = l.create_tag 'Deposits'
  l
end

date = DateTime.now
fake_transactions_data = [
  {amount: '223.43', tags: tag_ids_by_name['food'], comment: 'Food for a week'},
  {amount: '325.01', tags: [tag_ids_by_name['food'], tag_ids_by_name['lunch']], comment: 'Food in class and some pizza'},
  {amount: '163.22', tags: [tag_ids_by_name['food'], tag_ids_by_name['lunch']], comment: 'Food for roman'},
  {amount: '23.91', tags: [tag_ids_by_name['food'], tag_ids_by_name['entertainment']], comment: 'Some junk food'},
  {amount: '620.32', tags: [tag_ids_by_name['gas'], tag_ids_by_name['car']], comment: 'Gas and washing liquid'},
]

include Application::Commands

def create_account(ledger, name, currency, &block)
  @log.info "Creating new account: #{name}"
  account_id = CommonDomain::Infrastructure::AggregateId.new_id
  dispatch LedgerCommands::CreateNewAccount.new ledger.aggregate_id, account_id: account_id, name: name, initial_balance: 0, currency_code: currency.code
  if block_given? 
    yield(account_id) 
  else
    account_id
  end
end

def report_income account_id, amount, date, tags, comment
  dispatch AccountCommands::ReportIncome.new account_id, amount: amount, date: date, tag_ids: tags, comment: comment
end

def report_expence account_id, amount, date, tags, comment
  dispatch AccountCommands::ReportExpence.new account_id, amount: amount, date: date, tag_ids: tags, comment: comment
end

cache_uah_account_id = create_account ledger, 'Cache', uah do |account_id|
  report_income account_id, '36332.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  report_expence account_id, '12', date - 100, tag_ids_by_name['entertainment'], 'Ice cream'
  
  # Reporting in bulk directly. It just works faster.
  begin_unit_of_work({}) do |work|
    account = work.get_by_id Domain::Account, account_id
    100.times do
      data = fake_transactions_data[rand(fake_transactions_data.length)]
      account.report_expence data[:amount], date - rand(100), data[:tags], data[:comment]
    end
  end
  dispatch AccountCommands::ReportRefund.new account_id,
    amount: '310.00', date: DateTime.now, tag_ids: tag_ids_by_name['gas'], comment: 'Coworker gave back for gas'
  account_id
end

pb_credit_account_id = create_account ledger, 'PB Credit Card', uah do |account_id|
  report_income account_id, '23448.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  report_income account_id, '33448.57', date - 90, tag_ids_by_name['passive income'], 'Monthly income'
  report_income account_id, '43448.57', date - 80, tag_ids_by_name['passive income'], 'Monthly income'
  
  begin_unit_of_work({}) do |work|
    account = work.get_by_id Domain::Account, account_id
    100.times do
      data = fake_transactions_data[rand(fake_transactions_data.length)]
      account.report_expence data[:amount], date - rand(100), data[:tags], data[:comment]
    end
  end
  dispatch AccountCommands::ReportRefund.new account_id,
    amount: '50.00', date: DateTime.now, tag_ids: tag_ids_by_name['food'], comment: 'Shared expence refund'
  account_id
end

pb_deposit_id = create_account ledger, 'PB Deposit', uah

dispatch AccountCommands::ReportTransfer.new pb_credit_account_id, receiving_account_id: cache_uah_account_id,
  amount_sent: '15000.00', amount_received: '15000.00', date: DateTime.now, tag_ids: [], comment: 'Getting cache'

dispatch AccountCommands::ReportTransfer.new pb_credit_account_id, receiving_account_id: pb_deposit_id,
  amount_sent: '5000.00', amount_received: '5000.00', date: DateTime.now, tag_ids: tag_ids_by_name['deposits'], comment: 'Putting some money on deposit'

@context.event_store.dispatcher.wait_pending
