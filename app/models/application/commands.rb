module Application::Commands
  include CommonDomain::Command::DSL
  
  commands_group :AccountCommands do
    command :ReportIncome, :account_id, :ammount, :date, :tag_ids, :comment
    command :ReportExpence, :account_id, :ammount, :date, :tag_ids, :comment
  end
end