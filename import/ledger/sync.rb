gem 'rest_client'

# Has to be like this. Otherwise rails boot will reset gem search path.
require 'rest_client'

ledger_app_path = File.expand_path('../../..', __FILE__)
require File.expand_path('config/application', ledger_app_path)

Rails.application.config.log_config_path = File.expand_path('../log.xml', __FILE__)
Rails.application.config.paths['log'] = ['log/import.log']

Dir.chdir ledger_app_path do
  Rails.application.initialize!
end

module Ledger::Import
  require File.expand_path('../proxy', __FILE__)
  require File.expand_path('../sync_model', __FILE__)
end

@context = Rails.application.domain_context
@log = Rails.logger

sync_model = Ledger::Import::SyncModel.new @context
sync_model.do_initial_cleanup
sync_model.setup_users
sync_model.create_ledger

@proxy = Ledger::Import::BookerProxy.new 'http://booker.infora-soft.com'
raise 'BOOKER_LOGIN and BOOKER_PASSWORD should be added to .env' unless(ENV.key?('BOOKER_LOGIN') || ENV.key?('BOOKER_PASSWORD'))
@proxy.authenticate ENV['BOOKER_LOGIN'], ENV['BOOKER_PASSWORD']
sync_model.create_tags @proxy.get_tags
sync_model.create_categories @proxy.get_categories
accounts = @proxy.get_accounts
sync_model.create_accounts accounts

accounts.each { |account|
  @log.info "Fetching transactions for account: #{account['account']['name']}..."
  @proxy.fetch_transactions(account['account']['id']) do |transactions|
    sync_model.create_transactions account, transactions
  end
  sync_model.set_account_balance account
}

sync_model.finalize