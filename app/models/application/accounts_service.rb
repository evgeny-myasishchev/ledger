class Application::AccountsService < CommonDomain::CommandHandler
  include Application::Commands
  
  on AccountCommands::RenameAccount, begin_work: true do |work, command|
    account = work.get_by_id Domain::Account, command.aggregate_id
    account.rename command.name
  end
  
  on AccountCommands::SetAccountUnit, begin_work: true do |work, command|
    account = work.get_by_id Domain::Account, command.aggregate_id
    account.set_unit command.unit
  end
  
  on AccountCommands::ReportIncome, begin_work: true do |work, command|
    account = work.get_by_id Domain::Account, command.aggregate_id
    account.report_income command.ammount, command.date, command.tag_ids, command.comment
  end
  
  on AccountCommands::ReportExpence, begin_work: true do |work, command|
    account = work.get_by_id Domain::Account, command.aggregate_id
    account.report_expence command.ammount, command.date, command.tag_ids, command.comment
  end

  on AccountCommands::ReportRefund, begin_work: true do |work, command|
    account = work.get_by_id Domain::Account, command.aggregate_id
    account.report_refund command.ammount, command.date, command.tag_ids, command.comment
  end

  on AccountCommands::ReportTransfer, begin_work: true do |work, command|
    sending_account = work.get_by_id Domain::Account, command.aggregate_id
    receiving_account = work.get_by_id Domain::Account, command.receiving_account_id
    sending_transaction_id = sending_account.send_transfer receiving_account.aggregate_id,
      command.ammount_sent,
      command.date,
      command.tag_ids,
      command.comment
    receiving_account.receive_transfer sending_account.aggregate_id, sending_transaction_id,
      command.ammount_received,
      command.date,
      command.tag_ids,
      command.comment
  end
  
  on AccountCommands::AdjustAmmount, begin_work: true do |work, command|
    transaction = Projections::Transaction.find_by_transaction_id command.transaction_id
    account = work.get_by_id Domain::Account, transaction.account_id
    account.adjust_ammount command.transaction_id, command.ammount
  end
    
  on AccountCommands::AdjustComment do |command|
    perform_adjustment command.transaction_id do |account, transaction_id|
      account.adjust_comment transaction_id, command.comment
    end
  end
  
  on AccountCommands::AdjustDate do |command|
    perform_adjustment command.transaction_id do |account, transaction_id|
      account.adjust_date transaction_id, command.date
    end
  end
  
  on AccountCommands::AdjustTags do |command|
    perform_adjustment command.transaction_id do |account, transaction_id|
      account.adjust_tags transaction_id, command.tag_ids
    end
  end
  
  on AccountCommands::RemoveTransaction do |command|
    perform_adjustment command.transaction_id do |account, transaction_id|
      account.remove_transaction transaction_id
    end
  end
  
  private def perform_adjustment transaction_id, &block
    repository.begin_work do |work|
      transaction = Projections::Transaction.find_by_transaction_id transaction_id
      account = work.get_by_id Domain::Account, transaction.account_id
      yield(account, transaction_id)
  
      if transaction.is_transfer
        counterpart = transaction.get_transfer_counterpart
        counterpart_account = work.get_by_id Domain::Account, counterpart.account_id
        yield(counterpart_account, counterpart.transaction_id)
      end
    end
  end
end