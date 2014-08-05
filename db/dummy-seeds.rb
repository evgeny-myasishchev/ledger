# This file contains initialization of the dummy data that is used for development purposes
log = Rails.logger
context = Rails.application.domain_context

log.info 'Loadding dummy seeds...'

log.debug 'Doing existing data clenup...'
context.event_store.purge
context.projections.for_each { |projection| projection.cleanup! }

log.info 'Creating user dev@domain.com'
user = User.create_with(id: 1, password: 'password').find_or_create_by! email: 'dev@domain.com'

log.info 'Creating ledger for the user'
tag_ids_by_name = {}
ledger = context.repository.begin_work do |work|
  l = work.add_new Domain::Ledger.new.create user.id, 'Family'
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

uah = Currency['UAH']

date = DateTime.now
fake_transactions_data = [
  {ammount: '223.43', tags: tag_ids_by_name['food'], comment: 'Food for a week'},
  {ammount: '325.01', tags: [tag_ids_by_name['food'], tag_ids_by_name['lunch']], comment: 'Food in class and some pizza'},
  {ammount: '163.22', tags: [tag_ids_by_name['food'], tag_ids_by_name['lunch']], comment: 'Food for roman'},
  {ammount: '23.91', tags: [tag_ids_by_name['food'], tag_ids_by_name['entertainment']], comment: 'Some junk food'},
  {ammount: '620.32', tags: [tag_ids_by_name['gas'], tag_ids_by_name['car']], comment: 'Gas and washing liquid'},
]

cache_uah_account_id = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  account = work.add_new l.create_new_account('Cache', uah)
  account.aggregate_id
  account.report_income '36332.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  100.times do
    data = fake_transactions_data[rand(fake_transactions_data.length)]
    account.report_expence data[:ammount], date - rand(100), data[:tags], data[:comment]
  end
  account.aggregate_id
end

pb_credit_account_id = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  account = work.add_new l.create_new_account('PB Credit Card', uah)
  account.report_income '23448.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  account.report_income '33448.57', date - 90, tag_ids_by_name['passive income'], 'Monthly income'
  account.report_income '43448.57', date - 80, tag_ids_by_name['passive income'], 'Monthly income'
  100.times do
    data = fake_transactions_data[rand(fake_transactions_data.length)]
    account.report_expence data[:ammount], date - rand(100), data[:tags], data[:comment]
  end
  
  account.aggregate_id
end

pb_deposit_id = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  account = work.add_new l.create_new_account('PB Deposit', uah)
  account.aggregate_id
end

include Application::Commands

context.command_dispatcher.dispatch AccountCommands::ReportRefund.new cache_uah_account_id,
  ammount: '310.00', date: DateTime.now, tag_ids: tag_ids_by_name['gas'], comment: 'Coworker gave back for gas'

context.command_dispatcher.dispatch AccountCommands::ReportRefund.new pb_credit_account_id,
  ammount: '50.00', date: DateTime.now, tag_ids: tag_ids_by_name['food'], comment: 'Shared expence refund'

context.command_dispatcher.dispatch AccountCommands::ReportTransfer.new pb_credit_account_id, receiving_account_id: pb_deposit_id,
  ammount_sent: '5000.00', ammount_received: '5000.00', date: DateTime.now, tag_ids: tag_ids_by_name['deposits'], comment: 'Putting some money on deposit'

