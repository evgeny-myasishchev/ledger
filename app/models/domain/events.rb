module Domain::Events
  include CommonDomain::DomainEvent::DSL
  
  event :LedgerCreated, :user_id, :name
  event :LedgerRenamed, :name
  event :LedgerShared, :user_id
end