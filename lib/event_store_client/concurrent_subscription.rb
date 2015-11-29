# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers

  def initialize(target)
    @target = target
    super()
    @queue = init_worker_queue
  end

  def pull
    @queue.enq :pull
  end

  private

  def init_worker_queue
    queue = Queue.new
    Thread.new do
      loop do
        op = queue.deq
        if op == :pull
          logger.debug 'Pull operation requested. Pulling target.'
          @target.pull
        else
          logger.warn "Unexpected op: #{op}"
        end
      end
    end
    queue
  end

end