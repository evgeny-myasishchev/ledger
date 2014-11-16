class Application::LedgersService < CommonDomain::CommandHandler
  include Application::Commands
  include CommonDomain::NonAtomicUnitOfWork
  
  on LedgerCommands::CreateNewAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      initial_data = Domain::Account::InitialData.new command.name, command.initial_balance, Currency[command.currency_code], command.unit
      uow.add_new ledger.create_new_account command.account_id, initial_data
    end
  end
  
  on LedgerCommands::CloseAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.close_account account
    end
  end

  on LedgerCommands::ReopenAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.reopen_account account
    end
  end

  on LedgerCommands::RemoveAccount do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.remove_account account
    end
  end

  on LedgerCommands::CreateTag do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.create_tag command.name
    end
  end

  on LedgerCommands::ImportTagWithId do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.import_tag_with_id command.tag_id, command.name
    end
  end

  on LedgerCommands::RenameTag do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.rename_tag command.tag_id, command.name
    end
  end

  on LedgerCommands::RemoveTag do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.remove_tag command.tag_id
    end
  end

  on LedgerCommands::CreateCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.create_category command.name
    end
  end

  on LedgerCommands::ImportCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.import_category command.category_id, command.display_order, command.name
    end
  end

  on LedgerCommands::RenameCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.rename_category command.category_id, command.name
    end
  end

  on LedgerCommands::RemoveCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      ledger.remove_category command.category_id
    end
  end

  on LedgerCommands::SetAccountCategory do |command|
    begin_unit_of_work command.headers do |uow|
      ledger = uow.get_by_id Domain::Ledger, command.aggregate_id
      account = uow.get_by_id Domain::Account, command.account_id
      ledger.set_account_category account, command.category_id
    end
  end
end