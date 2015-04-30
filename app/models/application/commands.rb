module Application::Commands
  include Application::CommandFactories
  include CommonDomain::Command::DSL
  
  module AdjustTransactionBase
    def initialize(params)
      p = {transaction_id: params[:transaction_id]}.merge!(params[:command])
      p[:headers] = params[:headers] if params.key?(:headers)
      super(nil, p)
    end
    
    def self.included(receiver)
      receiver.include ActiveModel::Validations
      receiver.validates :transaction_id, presence: true
    end
  end
  
  commands_group :LedgerCommands do
    command :CreateNewAccount, :aggregate_id, :account_id, :name, :initial_balance, :currency_code, :unit do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id, :name, :initial_balance, :currency_code
    end
    command :CloseAccount, :aggregate_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    command :ReopenAccount, :aggregate_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    command :RemoveAccount, :aggregate_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id
    end
    command :CreateTag, :aggregate_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    command :ImportTagWithId, :aggregate_id, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id, :name
    end
    command :RenameTag, :aggregate_id, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id, :name
    end
    
    command :RemoveTag, :aggregate_id, :tag_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id
    end
    command :CreateCategory, :aggregate_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    command :ImportCategory, :aggregate_id, :category_id, :display_order, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id, :name
    end
    command :RenameCategory, :aggregate_id, :category_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id, :name
    end
    command :RemoveCategory, :aggregate_id, :category_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id
    end
    command :SetAccountCategory, :aggregate_id, :account_id, :category_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id, :category_id
    end
  end
  
  commands_group :AccountCommands do
    command :RenameAccount, :aggregate_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    command :SetAccountUnit, :aggregate_id, :unit do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id
    end
    
    # TODO: Rework other commands to use ActiveModel::Validations instead of custom factories
    command :ReportIncome, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportExpence, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportRefund, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportTransfer, :aggregate_id, :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date, :tag_ids, :comment do
      include TransferCommandFactory
    end
    command :AdjustAmount, :aggregate_id, :transaction_id, :amount do
      include AdjustTransactionBase
      validates :amount, :aggregate_id, presence: true
    end
    command :AdjustTags, :aggregate_id, :transaction_id, :tag_ids do
      include AdjustTransactionBase
    end
    command :AdjustDate, :aggregate_id, :transaction_id, :date do
      include AdjustTransactionBase
      validates :date, presence: true
    end
    command :AdjustComment, :aggregate_id, :transaction_id, :comment do
      include AdjustTransactionBase
    end
    command :RemoveTransaction, :aggregate_id, :transaction_id do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
      def initialize(params)
        super(nil, transaction_id: params[:id], headers: params[:headers])
      end
    end
    command :MoveTransaction, :aggregate_id, :transaction_id, :target_account_id do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
      validates :target_account_id, presence: true
      def initialize(params)
        super(nil, transaction_id: params[:id], target_account_id: params[:target_account_id], headers: params[:headers])
      end
    end
  end
  
  commands_group :PendingTransactionCommands do
    module PendingTransactionBaseCommand
      def self.included(receiver)
        receiver.include ActiveModel::Validations
        receiver.validates :aggregate_id, presence: true
        receiver.send(:alias_method, :transaction_id, :aggregate_id)
      end
    end  
    command :ReportPendingTransaction, :aggregate_id, :user, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      attr_writer :user
      include PendingTransactionBaseCommand
    end
    command :AdjustPendingTransaction, :aggregate_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionBaseCommand
    end
    command :ApprovePendingTransaction, :aggregate_id do
      include PendingTransactionBaseCommand
    end
    command :AdjustAndApprovePendingTransaction, :aggregate_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionBaseCommand
    end
    command :RejectPendingTransaction, :aggregate_id do
      include PendingTransactionBaseCommand
    end
  end
end
