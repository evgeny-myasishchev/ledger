class DomainContext < CommonDomain::DomainContext
  include CommonDomain
  
  attr_reader :command_dispatch_middleware
  
  def with_event_store
    bootstrap_event_store do |with|
      with.log4r_logging
      with.sql_persistence(event_store_database_config, orm_log_level: :debug).compress
    end
  end
  
  def with_command_handlers
    bootstrap_command_handlers do |dispatcher|
      dispatcher.register Application::LedgersService.new(repository_factory)
      dispatcher.register Application::AccountsService.new(repository_factory)
      dispatcher.register Application::PendingTransactionsService.new(repository_factory)
    end
  end
  
  def with_services
    
  end
  
  def with_command_dispatch_middleware
    dispatch = CommonDomain::DispatchCommand::Middleware::Dispatch.new(command_dispatcher)
    @command_dispatch_middleware = CommonDomain::DispatchCommand::Middleware::Stack.new(dispatch) do |stack|
      stack.with CommonDomain::DispatchCommand::Middleware::ValidateCommands
      stack.with CommonDomain::DispatchCommand::Middleware::TrackUser
    end
    self
  end
  
  def with_projections
    bootstrap_projections do |projections|
      projections.register :ledgers, ::Projections::Ledger.create_projection
      projections.register :accounts, ::Projections::Account.create_projection
      projections.register :transactions, ::Projections::Transaction.create_projection
      projections.register :tags, ::Projections::Tag.create_projection
      projections.register :categories, ::Projections::Category.create_projection
    end
  end
end