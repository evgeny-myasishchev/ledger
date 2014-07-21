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
end