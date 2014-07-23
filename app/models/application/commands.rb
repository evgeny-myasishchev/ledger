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
    command :AdjustComment, :transaction_id, :comment do
      include ActiveModel::Validations
      validates :transaction_id, presence: true, strict: true
      def initialize(params)
        super(nil, {transaction_id: params[:transaction_id]}.merge!(params[:command]))
      end
    end
  end
end
