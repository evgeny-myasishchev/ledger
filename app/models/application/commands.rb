module Application::Commands
  include Application::CommandsExtensions
  include CommonDomain::Command::DSL
  
  commands_group :LedgerCommands do
    command :CreateNewAccount, :ledger_id, :account_id, :name, :initial_balance, :currency_code, :unit do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :account_id, :name, :initial_balance, :currency_code
    end
    command :CloseAccount, :ledger_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :account_id
    end
    command :ReopenAccount, :ledger_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :account_id
    end
    command :RemoveAccount, :ledger_id, :account_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :account_id
    end
    command :CreateTag, :ledger_id, :name do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :name
    end
    command :RenameTag, :ledger_id, :tag_id, :name do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :tag_id, :name
    end
    
    command :RemoveTag, :ledger_id, :tag_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :tag_id
    end
    command :CreateCategory, :ledger_id, :name do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :name
    end
    command :RenameCategory, :ledger_id, :category_id, :name do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :category_id, :name
    end
    command :RemoveCategory, :ledger_id, :category_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :category_id
    end
    command :SetAccountCategory, :ledger_id, :account_id, :category_id do
      include ActiveModel::Validations
      validates_presence_of :ledger_id, :account_id, :category_id
    end
  end
  
  commands_group :AccountCommands do
    command :RenameAccount, :id, :name do
      include ActiveModel::Validations
      validates_presence_of :id, :name
    end
    command :SetAccountUnit, :id, :unit do
      include ActiveModel::Validations
      validates_presence_of :id
    end
    command :ReportIncome, :account_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportExpense, :account_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportRefund, :account_id, :transaction_id, :amount, :date, :tag_ids, :comment do
      include ReportRegularTransactionCommand
    end
    command :ReportTransfer, :account_id, :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date, :tag_ids, :comment do
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
    command :ConvertTransactionType, :account_id, :transaction_id, :type_id do
      include ActiveModel::Validations
      validates :account_id, :transaction_id, :type_id, presence: true
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
    command :ReportPendingTransaction, :id, :user, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :AdjustPendingTransaction, :id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :ApprovePendingTransaction, :id do
      include PendingTransactionCommand
    end
    command :AdjustAndApprovePendingTransaction, :id, :amount, :date, :tag_ids, :comment, :account_id, :type_id do
      include PendingTransactionCommand
    end
    command :AdjustAndApprovePendingTransferTransaction, :id, :amount, :date, :tag_ids, :comment, :account_id, :type_id, :receiving_account_id, :amount_received do
      include PendingTransactionCommand
      validates :receiving_account_id, presence: true
      validates :amount_received, presence: true
    end
    command :RejectPendingTransaction, :id do
      include PendingTransactionCommand
    end
  end
end
