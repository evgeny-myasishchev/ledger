Rails.application.configure do |app|
  app.class_eval do
    attr_reader :command_dispatch_middleware
    
    begin
      event_store = EventStore.bootstrap do |with|
        with.log4r_logging
        with
        .sql_persistence(app.config.database_configuration['event-store'])
        .compress
      end
    
      aggregates_builder = CommonDomain::Persistence::AggregatesBuilder.new
      persistence_factory = CommonDomain::PersistenceFactory.new(@event_store, aggregates_builder, Snapshot)
    
      command_dispatcher = CommonDomain::CommandDispatcher.new do |dispatcher|
        dispatcher.register Application::LedgersService.new(persistence_factory)
        dispatcher.register Application::AccountsService.new(persistence_factory)
        dispatcher.register Application::PendingTransactionsService.new(persistence_factory)
      end
    
      dispatch = CommonDomain::DispatchCommand::Middleware::Dispatch.new(command_dispatcher)
      @command_dispatch_middleware = CommonDomain::DispatchCommand::Middleware::Stack.new(dispatch) do |stack|
        stack.with CommonDomain::DispatchCommand::Middleware::ValidateCommands
        stack.with CommonDomain::DispatchCommand::Middleware::TrackUser
      end
    
      # TODO: Implement projections handling
      #     projections.register :ledgers, ::Projections::Ledger.create_projection
      #     projections.register :accounts, ::Projections::Account.create_projection
      #     projections.register :transactions, ::Projections::Transaction.create_projection
      #     projections.register :pending_transactions, ::Projections::PendingTransaction.create_projection
      #     projections.register :tags, ::Projections::Tag.create_projection
      #     projections.register :categories, ::Projections::Category.create_projection
    end unless Rails.env.test?
  end
end