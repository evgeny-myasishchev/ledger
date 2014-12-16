# If we are hosted by passenger we need to restart the dispatcher on each fork.
# Async dispatcher uses separate thread and forked threads are stopped.
if defined?(PhusionPassenger)
  app = Rails.application
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      app.domain_context.event_store.dispatcher.restart
      Rails.logger.info 'Passenger has forked worker process. Events dispatcher restarted.'
    else
      # We're in direct spawning mode. We don't need to do anything.
      fail 'Direct spawning needs to be tested'
    end
  end
end