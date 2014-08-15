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
  
  commands_group :LedgerCommands do
    command :CreateNewAccount, :account_id, :name, :initial_balance, :currency_code do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id, :name, :initial_balance, :currency_code
    end
    command :CloseAccount, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    command :ReopenAccount, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    command :RemoveAccount, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    
    command :CreateTag, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    
    command :RenameTag, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id, :name
    end
    
    command :RemoveTag, :tag_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id
    end
  end
  
  commands_group :AccountCommands do
    command :RenameAccount, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    
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
    end
    command :AdjustDate, :transaction_id, :date do
      include AdjustTransactionBase
      validates :date, presence: true
    end
    command :AdjustComment, :transaction_id, :comment do
      include AdjustTransactionBase
    end
    command :RemoveTransaction, :transaction_id do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
      def initialize(params)
        super(nil, transaction_id: params[:id])
      end
    end
  end
end
