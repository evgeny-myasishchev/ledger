class DomainContext < CommonDomain::DomainContext
  include CommonDomain
  include CommonDomain::DispatchCommand
  
  attr_reader :dispatch_middleware
  
  def initialize(&block)
    yield(self)
  end
  
  def with_event_store
    bootstrap_event_store do |with|
      with.log4r_logging
    end
  end
  
  def with_command_handlers
    bootstrap_command_handlers do |dispatcher|
      dispatcher.register Application::AccountsService.new(@repository)
    end
  end
  
  def with_services
    
  end
  
  def with_dispatch_middleware
    @dispatch_middleware = Middleware::Stack.new Middleware::Dispatch.new(command_dispatcher)
    @dispatch_middleware.with Middleware::TrackUser
    self
  end
  
  def with_projections
    bootstrap_projections do |projections|
      projections.register :ledgers, ::Projections::Ledger.create_projection
      projections.register :accounts, ::Projections::Account.create_projection
      projections.register :transactions, ::Projections::Transaction.create_projection
    end
  end
end