module Application::Commands
  include Application::CommandFactories
  include CommonDomain::Command::DSL
  commands_group :AccountCommands do
    command :ReportIncome, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportExpence, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportRefund, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportTransfer, :receiving_account_id, :ammount_sent, :ammount_received, :date, :tag_ids, :comment do
      include TransferCommandFactory
    end
  end
end