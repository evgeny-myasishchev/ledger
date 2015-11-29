# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers

  def initialize(target)
    @target = target
    super()
    @mutex = Mutex.new
    @pull_requested_cond = ConditionVariable.new
    @pull_requested = false
    init_worker
  end

  def pull
    logger.debug 'Requesting pull...'
    @mutex.synchronize do
      @pull_requested = true
      @pull_requested_cond.signal
      logger.debug 'Pull requested.'
    end
  end

  private

  def init_worker
    Thread.new(logger) do |logger|
      loop do
        @mutex.synchronize do
          unless @pull_requested
            logger.debug 'Waiting for pull request...'
            @pull_requested_cond.wait(@mutex)
          end
          @pull_requested = false
        end
        logger.debug 'Pull operation requested. Pulling target.'
        @target.pull
      end
    end
  end

end