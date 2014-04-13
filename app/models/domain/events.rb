module Domain::Events
  include CommonDomain::DomainEvent::DSL
  
  #Ledger events
  event :LedgerCreated, :user_id, :name
  event :LedgerRenamed, :name
  event :LedgerShared, :user_id
  event :AccountAddedToLedger, :account_id 
  event :LedgerAccountClosed, :account_id 
  
  #Account events
  event :AccountCreated, :ledger_id, :name, :currency_id
  event :AccountRenamed, :name
  event :AccountClosed
end