Rails.application.configure do |app|
  app.class_eval do
    attr_reader :event_store
    @event_store = EventStore.bootstrap do |with|
      with.log4r_logging
      with
        .sql_persistence(app.config.database_configuration['event-store'])
        .compress
    end
  end
end