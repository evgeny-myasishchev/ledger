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
  l
end

uah = Currency['UAH']

context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  work.add_new l.create_new_account('Cache', uah)
end

context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  date = DateTime.now
  account = work.add_new l.create_new_account('PB Credit Card', uah)
  account.report_income '23448.57', date - 100, tag_ids_by_name['passive income'], 'Monthly income'
  account.report_expence '223.40', date - 50, tag_ids_by_name['food'], 'Food for a week'
  account.report_expence '100.35', date - 30, [tag_ids_by_name['food'], tag_ids_by_name['lunch']], 'Food in class and some pizza'
  account.report_expence '163.41', date - 20, tag_ids_by_name['food'], 'Food for roman'
  account.report_expence '23.11', date, tag_ids_by_name['food'], 'Some junk food'
  account.report_expence '620.32', date, [tag_ids_by_name['car'], tag_ids_by_name['gas']], 'Gas'
end

pb_deposit = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  work.add_new l.create_new_account('PB Deposit', uah)
end