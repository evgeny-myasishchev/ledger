# If we are hosted by passenger we need to disconnect all sequel connections since they're getting broken
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      logger = Rails.logger
      logger.info 'Passenger has forked worker process.'
      ::Sequel::DATABASES.each{|db| 
        logger.info 'Disconnecting db connection'
        db.disconnect
      }
    else
      # We're in direct spawning mode. We don't need to do anything.
      fail 'Direct spawning needs to be tested'
    end
  end
end