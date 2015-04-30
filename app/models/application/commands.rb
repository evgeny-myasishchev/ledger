module Application::Commands
  include Application::CommandsExtensions
  include CommonDomain::Command::DSL
  
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
    command :ReportIncome, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportExpense, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportRefund, :aggregate_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportTransfer, :aggregate_id, :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date, :tag_ids, :comment do
      include ReportTransferTransactionCommand
    end
    command :AdjustAmount, :transaction_id, :amount do
      include AdjustTransactionCommand
      validates :amount, presence: true
    end
    command :AdjustTags, :transaction_id, :tag_ids do
      include AdjustTransactionCommand
    end
    command :AdjustDate, :transaction_id, :date do
      include AdjustTransactionCommand
      validates :date, presence: true
    end
    command :AdjustComment, :transaction_id, :comment do
      include AdjustTransactionCommand
    end
    command :RemoveTransaction, :transaction_id do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
    end
    command :MoveTransaction, :transaction_id, :target_account_id do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
      validates :target_account_id, presence: true
    end
  end
  
  commands_group :PendingTransactionCommands do
    command :ReportPendingTransaction, :aggregate_id, :user, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :AdjustPendingTransaction, :aggregate_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :ApprovePendingTransaction, :aggregate_id do
      include PendingTransactionCommand
    end
    command :AdjustAndApprovePendingTransaction, :aggregate_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :RejectPendingTransaction, :aggregate_id do
      include PendingTransactionCommand
    end
  end
end
