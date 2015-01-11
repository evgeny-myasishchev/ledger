class Application::PendingTransactionsService < CommonDomain::CommandHandler
  include Application::Commands
  include CommonDomain::NonAtomicUnitOfWork
  
end