Rails.application.configure do |app|
  singleton_class.class_eval do
    attr_reader :event_store, :event_store_client, :command_dispatch_app, :persistence_factory
  end
  
  app.config.pull_subscriptions_on_commit = true
  
  app.instance_eval do
    @event_store = EventStore.bootstrap do |with|
      with.log4r_logging
      with
        .sql_persistence(app.config.database_configuration[Rails.env])
        .compress
    end

    @event_store_client = EventStoreClient.new(@event_store, Checkpoint::Repository.new, pool: app.config.event_store_client.pool)
    
    aggregates_builder = CommonDomain::Persistence::AggregatesBuilder.new
    @persistence_factory = CommonDomain::PersistenceFactory.new(@event_store, aggregates_builder, Snapshot)
    @persistence_factory.hook after_commit: -> { 
      PullSubscriptionsJob.perform_later if app.config.pull_subscriptions_on_commit
    }
    
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

    # Please make sure that esc pool size is equals to number of subscriptions.
    # Also please make sure that pull size of the database config is bigger than esc pool size.
    @event_store_client.subscribe_handler ::Projections::Ledger.create_projection, group: :projections
    @event_store_client.subscribe_handler ::Projections::Account.create_projection, group: :projections
    @event_store_client.subscribe_handler ::Projections::Transaction.create_projection, group: :projections
    @event_store_client.subscribe_handler ::Projections::PendingTransaction.create_projection, group: :projections
    @event_store_client.subscribe_handler ::Projections::Tag.create_projection, group: :projections
    @event_store_client.subscribe_handler ::Projections::Category.create_projection, group: :projections
  end unless Rails.env.test?
end