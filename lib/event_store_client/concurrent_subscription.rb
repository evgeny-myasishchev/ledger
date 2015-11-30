require 'concurrent'

# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers

  def initialize(target, pool: Concurrent::FixedThreadPool.new(1))
    @target = target
    @pool = pool
    super()
    @semaphore = Concurrent::Semaphore.new(0)
    init_worker
  end

  def pull
    logger.debug 'Requesting pull...'
    @semaphore.release
  end

  private

  def init_worker
    @pool.post(logger) do |logger|
      begin
        Thread.current[:name] = @target.identifier #To simplify diagnostics
        loop do
          logger.debug 'Waiting for pull request...'
          @semaphore.acquire

          #Several pull requests could have been scheduled during a single target pull
          #drain is required to make just single pull in this case
          @semaphore.drain_permits

          logger.debug 'Pull operation requested. Pulling target.'
          @target.pull
          logger.debug 'Target pulled.'
        end
      rescue Exception => e
        # In prod error mailer is configured so email will be sent
        logger.fatal %{Pull failed: #{e}\n#{e.backtrace.join("\n")}}
      end
    end
  end

end