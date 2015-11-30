require 'concurrent'

class EventStoreClient
  include Loggable

  def initialize(event_store, checkpoints_repo, pool: Concurrent::FixedThreadPool.new(1))
    raise ArgumentError, 'event_store can not be nil' if event_store.nil?
    raise ArgumentError, 'checkpoints_repo can not be nil' if checkpoints_repo.nil?
    raise ArgumentError, 'pool can not be nil' if pool.nil?
    @event_store, @checkpoints_repo, @pool = event_store, checkpoints_repo, pool
    @subscriptions = []
    @subscriptions_by_group = {}
  end

  def subscriptions(group: nil)
    group.nil? ? @subscriptions : @subscriptions_by_group.fetch(group, [])
  end

  def subscribed_handlers(group: nil)
    subscriptions(group: group).map(&:handlers).flatten
  end

  def subscribe_handler(handler, group: nil)
    logger.debug "Subscribing handler: #{handler}"
    subscription = build_subscription(handler.class.name)
    subscription.add_handler(handler)
    register_subscription subscription, group: group
  end

  def pull_subscriptions(group: nil)
    logger.info "Pulling subscriptions. Group: '#{group}'."
    subscriptions(group: group).each { |s| s.pull }
  end

  def build_subscription(identifier)
    ConcurrentSubscription.new(PersistentSubscription.new(identifier, @event_store, @checkpoints_repo), pool: @pool)
  end

  private def register_subscription(subscription, group: nil)
    @subscriptions << subscription
    (@subscriptions_by_group[group] ||= []) << subscription unless group.nil?
  end
end