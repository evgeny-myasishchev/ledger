module Domain::Events
  include CommonDomain::DomainEvent::DSL
  
  #Ledger events
  event :LedgerCreated, :user_id, :name, :currency_code
  event :LedgerRenamed, :name
  event :LedgerShared, :user_id
  event :AccountAddedToLedger, :account_id
  event :LedgerAccountClosed, :account_id
  event :LedgerAccountReopened, :account_id
  event :LedgerAccountRemoved, :account_id
  event :TagCreated, :tag_id, :name
  event :TagRenamed, :tag_id, :name
  event :TagRemoved, :tag_id
  event :CategoryCreated, :category_id, :display_order, :name
  event :CategoryRenamed, :category_id, :name
  event :CategoryRemoved, :category_id
  event :AccountCategoryAssigned, :account_id, :category_id
  
  #Account events
  event :AccountCreated, :ledger_id, :sequential_number, :name, :initial_balance, :currency_code, :unit
  event :AccountRenamed, :name
  event :AccountUnitAdjusted, :unit
  event :AccountClosed
  event :AccountReopened
  event :AccountRemoved
  event :AccountBalanceChanged, :transaction_id, :balance
  event :TransactionReported, :transaction_id, :type_id, :amount, :date, :tag_ids, :comment
  event :TransferSent, :transaction_id, :receiving_account_id, :amount, :date, :tag_ids, :comment
  event :TransferReceived, :transaction_id, :sending_account_id, :sending_transaction_id, :amount, :date, :tag_ids, :comment
  event :TransactionAmountAdjusted, :transaction_id, :amount
  event :TransactionCommentAdjusted, :transaction_id, :comment
  event :TransactionDateAdjusted, :transaction_id, :date
  event :TransactionTagged, :transaction_id, :tag_id
  event :TransactionUntagged, :transaction_id, :tag_id
  event :TransactionRemoved, :transaction_id
  event :TransactionMovedTo, :target_account_id, :transaction_id
  event :TransactionMovedFrom, :sending_account_id, :transaction_id
  
  #Pending transaction events
  event :PendingTransactionReported, :user_id, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  event :PendingTransactionAdjusted, :amount, :date, :tag_ids, :comment, :account_id, :type_id
  event :PendingTransactionApproved
  event :PendingTransactionRejected
end