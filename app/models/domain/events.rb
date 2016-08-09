module Domain::Events
  include CommonDomain::DomainEvent::DSL

  # Ledger events
  event :LedgerCreated, :aggregate_id, :user_id, :name, :currency_code
  event :LedgerRenamed, :aggregate_id, :name
  event :LedgerShared, :aggregate_id, :user_id
  event :AccountAddedToLedger, :aggregate_id, :account_id
  event :LedgerAccountClosed, :aggregate_id, :account_id
  event :LedgerAccountReopened, :aggregate_id, :account_id
  event :LedgerAccountRemoved, :aggregate_id, :account_id
  event :TagCreated, :aggregate_id, :tag_id, :name
  event :TagRenamed, :aggregate_id, :tag_id, :name
  event :TagRemoved, :aggregate_id, :tag_id
  event :CategoryCreated, :aggregate_id, :category_id, :display_order, :name
  event :CategoryRenamed, :aggregate_id, :category_id, :name
  event :CategoryRemoved, :aggregate_id, :category_id
  event :AccountCategoryAssigned, :aggregate_id, :account_id, :category_id

  # Account events
  event :AccountCreated, :aggregate_id, :ledger_id, :sequential_number, :name, :initial_balance, :currency_code, :unit
  event :AccountRenamed, :aggregate_id, :name
  event :AccountUnitAdjusted, :aggregate_id, :unit
  event :AccountClosed, :aggregate_id
  event :AccountReopened, :aggregate_id
  event :AccountRemoved, :aggregate_id
  event :AccountBalanceChanged, :aggregate_id, :transaction_id, :balance
  event :TransactionReported, :aggregate_id, :transaction_id, :type_id, :amount, :date, :tag_ids, :comment
  event :TransferSent, :aggregate_id, :transaction_id, :receiving_account_id, :amount, :date, :tag_ids, :comment
  event :TransferReceived, :aggregate_id, :transaction_id, :sending_account_id, :sending_transaction_id, :amount, :date, :tag_ids, :comment
  event :TransactionAmountAdjusted, :aggregate_id, :transaction_id, :amount
  event :TransactionCommentAdjusted, :aggregate_id, :transaction_id, :comment
  event :TransactionDateAdjusted, :aggregate_id, :transaction_id, :date
  event :TransactionTagged, :aggregate_id, :transaction_id, :tag_id
  event :TransactionUntagged, :aggregate_id, :transaction_id, :tag_id
  event :TransactionRemoved, :aggregate_id, :transaction_id
  event :TransactionMovedTo, :aggregate_id, :target_account_id, :transaction_id
  event :TransactionMovedFrom, :aggregate_id, :sending_account_id, :transaction_id
  event :TransactionTypeConverted, :aggregate_id, :transaction_id, :type_id

  # Pending transaction events
  event :PendingTransactionReported, :aggregate_id, :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  event :PendingTransactionRestored, :aggregate_id, :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  event :PendingTransactionAdjusted, :aggregate_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  event :PendingTransactionApproved, :aggregate_id
  event :PendingTransactionRejected, :aggregate_id
end
