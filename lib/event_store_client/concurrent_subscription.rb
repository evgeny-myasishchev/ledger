# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers

  def initialize(target)
    @target = target
    super()
    @monitor = Monitor.new
    @pull_requested_cond = @monitor.new_cond
    @pull_requested = false
    init_worker
  end

  def pull
    logger.debug 'Requesting pull...'
    @monitor.synchronize do
      @pull_requested = true
      @pull_requested_cond.signal
      logger.debug 'Pull requested.'
    end
  end

  private

  def init_worker
    Thread.new(logger) do |logger|
      begin
        Thread.current[:name] = @target.identifier
        loop do
          @monitor.synchronize do
            logger.debug 'Waiting for pull request...'
            @pull_requested_cond.wait_until { @pull_requested }
            @pull_requested = false
          end
          logger.debug 'Pull operation requested. Pulling target.'
          @target.pull
        end
      rescue Exception => e
        # In prod error mailer is configured so email will be sent
        logger.fatal "Pull failed.\n  #{e}\n  #{e.backtrace.join('  \n')}"
      end
    end
  end

end