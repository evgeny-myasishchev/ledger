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
    command :CreateNewAccount, :account_id, :name, :initial_balance, :currency_code, :unit do
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
    command :ImportTagWithId, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id, :name
    end
    command :RenameTag, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id, :name
    end
    
    command :RemoveTag, :tag_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :tag_id
    end
    command :CreateCategory, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    command :ImportCategory, :category_id, :display_order, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id, :name
    end
    command :RenameCategory, :category_id, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id, :name
    end
    command :RemoveCategory, :category_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :category_id
    end
    command :SetAccountCategory, :account_id, :category_id do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :account_id, :category_id
    end
  end
  
  commands_group :AccountCommands do
    command :RenameAccount, :name do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id, :name
    end
    command :SetAccountUnit, :unit do
      include ActiveModel::Validations
      validates_presence_of :aggregate_id
    end
    
    # TODO: Rework other commands to use ActiveModel::Validations instead of custom factories
    command :ReportIncome, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportExpence, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportRefund, :transaction_id, :amount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportTransfer, :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date, :tag_ids, :comment do
      include TransferCommandFactory
    end
    command :AdjustAmount, :transaction_id, :amount do
      include AdjustTransactionBase
      validates :amount, presence: true
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
        super(nil, transaction_id: params[:id], headers: params[:headers])
      end
    end
    command :MoveTransaction, :transaction_id, :target_account_id do
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
    command :ReportPendingTransaction, :user, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      attr_writer :user
      include PendingTransactionBaseCommand
    end
    command :AdjustPendingTransaction, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionBaseCommand
    end
    command :ApprovePendingTransaction do
      include PendingTransactionBaseCommand
    end
    command :AdjustAndApprovePendingTransaction, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionBaseCommand
    end
    command :RejectPendingTransaction do
      include PendingTransactionBaseCommand
    end
  end
end
