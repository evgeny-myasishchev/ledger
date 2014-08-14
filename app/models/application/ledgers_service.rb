class Application::LedgersService < CommonDomain::CommandHandler
  include Application::Commands
  
  on LedgerCommands::CreateNewAccount, begin_work: true do |work, command|
    ledger = work.get_by_id Domain::Ledger, command.aggregate_id
    initial_data = Domain::Account::InitialData.new command.name, command.initial_balance, Currency[command.currency_code]
    work.add_new ledger.create_new_account command.account_id, initial_data
  end
  
  on LedgerCommands::CloseAccount, begin_work: true do |work, command|
    ledger = work.get_by_id Domain::Ledger, command.aggregate_id
    account = work.get_by_id Domain::Account, command.account_id
    ledger.close_account account
  end
  
  on LedgerCommands::ReopenAccount, begin_work: true do |work, command|
    ledger = work.get_by_id Domain::Ledger, command.aggregate_id
    account = work.get_by_id Domain::Account, command.account_id
    ledger.reopen_account account
  end
  
  on LedgerCommands::RemoveAccount, begin_work: true do |work, command|
    ledger = work.get_by_id Domain::Ledger, command.aggregate_id
    account = work.get_by_id Domain::Account, command.account_id
    ledger.remove_account account
  end
end