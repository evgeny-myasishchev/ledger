# Concurrent subscription does pull concurrently (in a dedicated thread)
class EventStoreClient::ConcurrentSubscription < EventStoreClient::Subscription
  extend Forwardable

  def_delegators :@target, :add_handler, :handlers

  def initialize(target)
    @target = target
    super()
  end
end