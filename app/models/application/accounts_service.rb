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
    raise "Not implemented"
  end

  on AccountCommands::ReportTransfer, begin_work: true do |work, command|
    raise "Not implemented"
  end
end