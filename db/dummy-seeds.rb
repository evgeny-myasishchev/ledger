# This file contains initialization of the dummy data that is used for development purposes
log = Rails.logger
context = Rails.application.domain_context

log.info 'Loadding dummy seeds...'

log.debug 'Doing existing data clenup...'
User.delete_all
context.event_store.purge
context.projections.for_each { |projection| projection.cleanup! }

log.info 'Creating user dev@domain.com'
user = User.create! email: 'dev@domain.com', password: 'password'

log.info 'Creating ledger for the user'
ledger = context.repository.begin_work do |work|
  work.add_new Domain::Ledger.new.create user.id, 'Family'
end

uah = Currency.find_by code: 'UAH'

cache = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  work.add_new l.create_new_account('Cache', uah)
end

pb_credit_card = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  work.add_new l.create_new_account('PB Credit Card', uah)
end

pb_deposit = context.repository.begin_work do |work|
  l = work.get_by_id(Domain::Ledger, ledger.aggregate_id)
  work.add_new l.create_new_account('PB Deposit', uah)
end