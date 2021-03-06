# This file contains initialization of the dummy data that is used for development purposes

logger = Rails.logger
@logger = logger
@app = Rails.application
@persistence_factory = @app.persistence_factory
@app.config.pull_subscriptions_on_commit = false

logger.info 'Loadding dummy seeds...'

logger.debug 'Doing existing data clenup...'
@app.event_store.purge!
@app.event_store_client
  .subscribed_handlers(group: :projections)
  .each { |projection| projection.purge! }

#TODO Purge projections
# @app.projections.for_each { |projection| projection.cleanup! }

dummy_user_name = ENV['DUMMY_USER_NAME'] || 'dev@my-ledger.com'
logger.info "Creating user #{dummy_user_name}"
user = User.create_with(password: 'password').find_or_create_by! email: dummy_user_name

@dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user.id, '127.0.0.1'
@headers = {user_id: user.id, ip_address: '127.0.0.1'}

def dispatch command
  @app.command_dispatch_app.call command, @dispatch_context
end

uah = Currency['UAH']
usd = Currency['USD']
xau = Currency['XAU']
xxx = Currency['XXX']

logger.info 'Creating ledger for the user'
tag_ids_by_name = {}
ledger = @persistence_factory.begin_unit_of_work({}) do |work|
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

def new_id
  CommonDomain::Aggregate.new_id
end

def create_account(ledger, name, currency, &block)
  @logger.info "Creating new account: #{name}"
  account_id = new_id
  dispatch LedgerCommands::CreateNewAccount.new ledger_id: ledger.aggregate_id, account_id: account_id, name: name, initial_balance: 0, currency_code: currency.code, unit: nil
  if block_given? 
    yield(account_id) 
  else
    account_id
  end
end

def report_income account_id, amount, date, tags, comment
  dispatch AccountCommands::ReportIncome.new account_id: account_id, transaction_id: new_id, amount: amount, date: date, tag_ids: tags, comment: comment
end

def report_expense account_id, amount, date, tags, comment
  dispatch AccountCommands::ReportExpense.new account_id: account_id, transaction_id: new_id, amount: amount, date: date, tag_ids: tags, comment: comment
end

cache_uah_account_id = create_account ledger, 'Cache', uah do |account_id|
  report_income account_id, '36332.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  report_expense account_id, '12', date - 100, tag_ids_by_name['entertainment'], 'Ice cream'
  
  # Reporting in bulk directly. It just works faster.
  @persistence_factory.begin_unit_of_work(@headers) do |work|
    account = work.get_by_id Domain::Account, account_id
    100.times do
      data = fake_transactions_data[rand(fake_transactions_data.length)]
      account.report_expense new_id, data[:amount], date - rand(100), data[:tags], data[:comment]
    end
  end
  dispatch AccountCommands::ReportRefund.new account_id: account_id, transaction_id: new_id,
    amount: '310.00', date: DateTime.now, tag_ids: tag_ids_by_name['gas'], comment: 'Coworker gave back for gas'
  account_id
end

create_account ledger, 'Cache USD', usd do |account_id|
  report_income account_id, '1322.12', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  report_expense account_id, '12', date - 100, tag_ids_by_name['entertainment'], 'Ice cream'
  
  # Reporting in bulk directly. It just works faster.
  @persistence_factory.begin_unit_of_work(@headers) do |work|
    account = work.get_by_id Domain::Account, account_id
    100.times do
      data = fake_transactions_data[rand(fake_transactions_data.length)]
      account.report_expense new_id, data[:amount], date - rand(100), data[:tags], data[:comment]
    end
  end
end

create_account ledger, 'Gold', xau do |account_id|
  report_income account_id, '100', date - 100, tag_ids_by_name['passive income'], 'Got some present'
end

create_account ledger, 'Fuel', xxx do |account_id|
  report_income account_id, '100', date - 100, tag_ids_by_name['passive income'], 'Got some corporate fuel'
end

pb_credit_account_id = create_account ledger, 'PB Credit Card', uah do |account_id|
  report_income account_id, '23448.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  report_income account_id, '33448.57', date - 90, tag_ids_by_name['passive income'], 'Monthly income'
  report_income account_id, '43448.57', date - 80, tag_ids_by_name['passive income'], 'Monthly income'
  
  @persistence_factory.begin_unit_of_work(@headers) do |work|
    account = work.get_by_id Domain::Account, account_id
    100.times do
      data = fake_transactions_data[rand(fake_transactions_data.length)]
      account.report_expense new_id, data[:amount], date - rand(100), data[:tags], data[:comment]
    end
  end
  dispatch AccountCommands::ReportRefund.new account_id: account_id, transaction_id: new_id,
    amount: '50.00', date: DateTime.now, tag_ids: tag_ids_by_name['food'], comment: 'Shared expense refund'
  account_id
end

pb_deposit_id = create_account ledger, 'PB Deposit', uah

dispatch AccountCommands::ReportTransfer.new account_id: pb_credit_account_id, sending_transaction_id: new_id, receiving_account_id: cache_uah_account_id, receiving_transaction_id: new_id,
  amount_sent: '15000.00', amount_received: '15000.00', date: DateTime.now, tag_ids: [], comment: 'Getting cache'

dispatch AccountCommands::ReportTransfer.new account_id: pb_credit_account_id, sending_transaction_id: new_id, receiving_account_id: pb_deposit_id, receiving_transaction_id: new_id,
  amount_sent: '5000.00', amount_received: '5000.00', date: DateTime.now, tag_ids: tag_ids_by_name['deposits'], comment: 'Putting some money on deposit'

@app.event_store_client.pull_subscriptions