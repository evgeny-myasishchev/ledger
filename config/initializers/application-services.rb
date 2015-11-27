Rails.application.configure do |app|
  singleton_class.class_eval do
    attr_reader :event_store, :event_store_client, :command_dispatch_app, :persistence_factory
  end
  
  app.instance_eval do
    @event_store = EventStore.bootstrap do |with|
      with.log4r_logging
      with
        .sql_persistence(app.config.database_configuration['event-store'])
        .compress
    end

    #TODO: Implement real (AR based) checkpoints repo
    @event_store_client = EventStoreClient.new(@event_store, CheckpointsRepository::InMemory.new)
    
    aggregates_builder = CommonDomain::Persistence::AggregatesBuilder.new
    @persistence_factory = CommonDomain::PersistenceFactory.new(@event_store, aggregates_builder, Snapshot)
    
    command_dispatcher = CommonDomain::CommandDispatcher.new do |dispatcher|
      dispatcher.register Application::LedgersService.new(@persistence_factory)
      dispatcher.register Application::AccountsService.new(@persistence_factory)
      dispatcher.register Application::PendingTransactionsService.new(@persistence_factory)
    end
    
    dispatch = CommonDomain::DispatchCommand::Middleware::Dispatch.new(command_dispatcher)
    @command_dispatch_app = CommonDomain::DispatchCommand::Middleware::Stack.new(dispatch) do |stack|
      stack.with CommonDomain::DispatchCommand::Middleware::ValidateCommands
      stack.with CommonDomain::DispatchCommand::Middleware::TrackUser
    end

    @event_store_client.subscribe_handler ::Projections::Ledger.create_projection
    @event_store_client.subscribe_handler ::Projections::Account.create_projection
    @event_store_client.subscribe_handler ::Projections::Transaction.create_projection
    @event_store_client.subscribe_handler ::Projections::PendingTransaction.create_projection
    @event_store_client.subscribe_handler ::Projections::Tag.create_projection
    @event_store_client.subscribe_handler ::Projections::Category.create_projection
  end unless Rails.env.test?
end