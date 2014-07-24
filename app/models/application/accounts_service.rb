class Application::AccountsService < CommonDomain::CommandHandler
  include Application::Commands
  
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
  
  on AccountCommands::AdjustComment, begin_work: true do |work, command|
    transaction = Projections::Transaction.find_by_transaction_id command.transaction_id
    account = work.get_by_id Domain::Account, transaction.account_id
    account.adjust_comment command.transaction_id, command.comment
    
    if transaction.is_transfer
      counterpart = transaction.get_transfer_counterpart
      counterpart_account = work.get_by_id Domain::Account, counterpart.account_id
      counterpart_account.adjust_comment counterpart.transaction_id, command.comment
    end
  end
end