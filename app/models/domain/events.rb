module Domain::Events
  include CommonDomain::DomainEvent::DSL
  
  #Ledger events
  event :LedgerCreated, :user_id, :name
  event :LedgerRenamed, :name
  event :LedgerShared, :user_id
  event :AccountAddedToLedger, :account_id
  event :LedgerAccountClosed, :account_id
  event :TagCreated, :tag_id, :name
  event :TagRenamed, :tag_id, :name
  event :TagRemoved, :tag_id
  
  #Account events
  event :AccountCreated, :ledger_id, :sequential_number, :name, :initial_balance, :currency_code
  event :AccountRenamed, :name
  event :AccountClosed
  event :AccountBalanceChanged, :transaction_id, :balance
  event :TransactionReported, :transaction_id, :type_id, :ammount, :date, :tag_ids, :comment
  event :TransferSent, :transaction_id, :receiving_account_id, :ammount, :date, :tag_ids, :comment
  event :TransferReceived, :transaction_id, :sending_account_id, :sending_transaction_id, :ammount, :date, :tag_ids, :comment
  event :TransactionAmmountAdjusted, :transaction_id, :ammount
  event :TransactionCommentAdjusted, :transaction_id, :comment
  event :TransactionDateAdjusted, :transaction_id, :date
  event :TransactionTagged, :transaction_id, :tag_id
  event :TransactionUntagged, :transaction_id, :tag_id
  event :TransactionRemoved, :transaction_id
end