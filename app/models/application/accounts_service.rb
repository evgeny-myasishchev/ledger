class Application::AccountsService < CommonDomain::CommandHandler
  include Application::Commands
  include CommonDomain::UnitOfWork::Atomic
  
  handle(AccountCommands::RenameAccount).with(Domain::Account).using(:rename)

  handle(AccountCommands::SetAccountUnit).with(Domain::Account).using(:set_unit)

  handle(AccountCommands::ReportIncome, id: :account_id).with(Domain::Account)

  handle(AccountCommands::ReportExpense, id: :account_id).with(Domain::Account)

  handle(AccountCommands::ReportRefund, id: :account_id).with(Domain::Account)

  on AccountCommands::ReportTransfer do |command|
    begin_unit_of_work command.headers do |uow|
      sending_account = uow.get_by_id Domain::Account, command.account_id
      receiving_account = uow.get_by_id Domain::Account, command.receiving_account_id
      sending_transaction_id = sending_account.send_transfer command.sending_transaction_id, receiving_account.aggregate_id,
        command.amount_sent,
        command.date,
        command.tag_ids,
        command.comment
      receiving_account.receive_transfer command.receiving_transaction_id, sending_account.aggregate_id, sending_transaction_id,
        command.amount_received,
        command.date,
        command.tag_ids,
        command.comment
    end
  end

  on AccountCommands::AdjustAmount do |command|
    transaction = Projections::Transaction.find_by_transaction_id command.transaction_id
    begin_unit_of_work command.headers do |uow|
      account = uow.get_by_id Domain::Account, transaction.account_id
      account.adjust_amount command.transaction_id, command.amount
    end
  end

  on AccountCommands::AdjustComment do |command|
    perform_adjustment command.transaction_id, command.headers do |account, transaction_id|
      account.adjust_comment transaction_id, command.comment
    end
  end

  on AccountCommands::AdjustDate do |command|
    perform_adjustment command.transaction_id, command.headers do |account, transaction_id|
      account.adjust_date transaction_id, command.date
    end
  end

  on AccountCommands::AdjustTags do |command|
    perform_adjustment command.transaction_id, command.headers do |account, transaction_id|
      account.adjust_tags transaction_id, command.tag_ids
    end
  end
  
  handle(AccountCommands::ConvertTransactionType, id: :account_id).with(Domain::Account)

  on AccountCommands::RemoveTransaction do |command|
    perform_adjustment command.transaction_id, command.headers do |account, transaction_id|
      account.remove_transaction transaction_id
    end
  end
  

  on AccountCommands::MoveTransaction do |command|
    transaction = Projections::Transaction.find_by_transaction_id command.transaction_id
    begin_unit_of_work command.headers do |uow|
      account = uow.get_by_id Domain::Account, transaction.account_id
      target_account = uow.get_by_id Domain::Account, command.target_account_id
      account.move_transaction_to command.transaction_id, target_account
    end
  end

  private def perform_adjustment transaction_id, headers, &block
    transaction = Projections::Transaction.find_by_transaction_id transaction_id
    begin_unit_of_work headers do |uow|
      account = uow.get_by_id Domain::Account, transaction.account_id
      yield(account, transaction_id)
      if transaction.is_transfer
        counterpart = transaction.get_transfer_counterpart
        counterpart_account = uow.get_by_id Domain::Account, counterpart.account_id
        yield(counterpart_account, counterpart.transaction_id)
      end
    end
  end
end