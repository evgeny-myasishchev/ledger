class Application::LedgersService < CommonDomain::CommandHandler
  include Application::Commands
  
  on LedgerCommands::CreateNewAccount, begin_work: true do |work, command|
    ledger = work.get_by_id Domain::Ledger, command.aggregate_id
    initial_data = Domain::Account::InitialData.new command.name, command.initial_balance, Currency[command.currency_code]
    work.add_new ledger.create_new_account command.account_id, initial_data
  end
end