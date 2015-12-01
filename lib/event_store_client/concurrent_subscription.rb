require 'concurrent'

# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers, :identifier

  def initialize(target, pool: Concurrent::FixedThreadPool.new(1))
    @target = target
    @pool = pool
    @pulling_target = Concurrent::TVar.new(false)
    @pull_again_requested = Concurrent::TVar.new(false)
    super()
  end

  def pull
    Concurrent::atomically do
      if @pulling_target.value
        logger.debug 'Target is already being pulled. Will be pulled again when done.'
        @pull_again_requested.value = true
      else
        logger.debug 'Scheduling target pull...'
        schedule_pull_target
      end
    end
  end

  private

  def pull_target
    logger.debug 'Pulling target.'
    @target.pull
    logger.debug 'Target pulled.'
    Concurrent::atomically do
      @pulling_target.value = false
      if @pull_again_requested.value
        @pull_again_requested.value = false
        logger.debug 'Another pull has been requested so scheduling pulling again.'
        schedule_pull_target
      end
    end
  rescue Exception => e
    # In prod error mailer is configured so email will be sent
    logger.fatal %{Pull failed: #{e}\n#{e.backtrace.join("\n")}}
  end

  def schedule_pull_target
    @pulling_target.value = true
    @pool.post { pull_target }
  end
end