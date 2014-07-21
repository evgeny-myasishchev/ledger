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
  tag_ids_by_name['car'] = l.create_tag 'Car'
  tag_ids_by_name['gas'] = l.create_tag 'Gas'
  tag_ids_by_name['active income'] = l.create_tag 'Active Income'
  tag_ids_by_name['passive income'] = l.create_tag 'Passive Income'
  tag_ids_by_name['deposits'] = l.create_tag 'Deposits'
  l
end

uah = Currency['UAH']

cache_uah_account_id = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  account = work.add_new l.create_new_account('Cache', uah)
  account.aggregate_id
end

pb_credit_account_id = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  date = DateTime.now
  account = work.add_new l.create_new_account('PB Credit Card', uah)
  account.report_income '23448.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  account.report_expence '223.40', date - 50, tag_ids_by_name['food'], 'Food for a week'
  account.report_expence '100.35', date - 30, [tag_ids_by_name['food'], tag_ids_by_name['lunch']], 'Food in class and some pizza'
  account.report_expence '163.41', date - 20, tag_ids_by_name['food'], 'Food for roman'
  account.report_expence '23.11', date, tag_ids_by_name['food'], 'Some junk food'
  account.report_expence '620.32', date, [tag_ids_by_name['car'], tag_ids_by_name['gas']], 'Gas'
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
  
context.command_dispatcher.dispatch AccountCommands::ReportTransfer.new pb_deposit_id, receiving_account_id: pb_deposit_id,
  ammount_sent: '5000.00', ammount_received: '5000.00', date: DateTime.now, tag_ids: tag_ids_by_name['deposits'], comment: 'Putting some money on deposit'

