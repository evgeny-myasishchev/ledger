module Application::Commands
  include Application::CommandFactories
  include CommonDomain::Command::DSL
  
  module AdjustTransactionBase
    def initialize(params)
      super(nil, {transaction_id: params[:transaction_id]}.merge!(params[:command]))
    end
    
    def self.included(receiver)
      receiver.include ActiveModel::Validations
      receiver.validates :transaction_id, presence: true
    end
  end
  
  commands_group :AccountCommands do
    # TODO: Rework other commands to use ActiveModel::Validations instead of custom factories
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
    command :AdjustAmmount, :transaction_id, :ammount do
      include AdjustTransactionBase
      validates :ammount, presence: true
    end
    command :AdjustTags, :transaction_id, :tag_ids do
      include AdjustTransactionBase
      validates :tag_ids, presence: true
    end
    command :AdjustDate, :transaction_id, :date do
      include AdjustTransactionBase
      validates :date, presence: true
    end
    command :AdjustComment, :transaction_id, :comment do
      include AdjustTransactionBase
    end
  end
end
