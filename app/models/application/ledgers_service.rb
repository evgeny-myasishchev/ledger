class Application::LedgersService < CommonDomain::CommandHandler
  include Application::Commands
  include CommonDomain::UnitOfWork::Atomic
  
  on LedgerCommands::CreateNewAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.ledger_id
      initial_data = Domain::Account::InitialData.new command.name, command.initial_balance, Currency[command.currency_code], command.unit
      uow.add_new ledger.create_new_account command.account_id, initial_data
    end
  end
  
  on LedgerCommands::CloseAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.ledger_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.close_account account
    end
  end

  on LedgerCommands::ReopenAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.ledger_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.reopen_account account
    end
  end

  on LedgerCommands::RemoveAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.ledger_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.remove_account account
    end
  end
  
  handle(LedgerCommands::CreateTag, id: :ledger_id).with(Domain::Ledger)
  handle(LedgerCommands::RenameTag, id: :ledger_id).with(Domain::Ledger)
  handle(LedgerCommands::RemoveTag, id: :ledger_id).with(Domain::Ledger)
  
  handle(LedgerCommands::CreateCategory, id: :ledger_id).with(Domain::Ledger)
  handle(LedgerCommands::RenameCategory, id: :ledger_id).with(Domain::Ledger)
  handle(LedgerCommands::RemoveCategory, id: :ledger_id).with(Domain::Ledger)

  on LedgerCommands::SetAccountCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.ledger_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.set_account_category account, command.category_id
    end
  end
end