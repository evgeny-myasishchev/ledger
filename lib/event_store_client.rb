class EventStoreClient
  include Loggable

  def initialize event_store, checkpoints_repo
    raise ArgumentError, 'event_store can not be nil' if event_store.nil?
    raise ArgumentError, 'checkpoints_repo can not be nil' if checkpoints_repo.nil?
    @event_store, @checkpoints_repo = event_store, checkpoints_repo
    @subscriptions = []
    @subscriptions_by_group = {}
  end
  
  def subscriptions group: nil
    group.nil? ? @subscriptions : @subscriptions_by_group.fetch(group, [])
  end

  def subscribed_handlers group: nil
    subscriptions(group: group).map(&:handlers).flatten
  end

  def subscribe_handler handler, group: nil
    log.debug "Subscribing handler: #{handler}"
    subscription = build_subscription(handler.class.name)
    subscription.add_handler(handler)
    register_subscription subscription, group: group
  end

  #TODO: Add pull specified groups only
  def pull_subscriptions group: nil
    log.info "Pulling subscriptions. Group: '#{group}'."
    subscriptions(group: group).each { |s| s.pull }
  end

  def build_subscription identifier
    PersistentSubscription.new identifier, @event_store, @checkpoints_repo
  end
  
  private def register_subscription subscription, group: nil
    @subscriptions << subscription
    (@subscriptions_by_group[group] ||= []) << subscription unless group.nil?
  end

  #
  # The subscription will persist checkpoint of last commit that has been successfully handled by all handlers.
  # It does not automatically know if new commits are available so pull must be called explicitly.
  #
  class PersistentSubscription
    include Loggable
    
    attr_reader :handlers

    def initialize identifier, event_store, checkpoints_repo
      raise ArgumentError, 'identifier can not be nil' if identifier.nil?
      raise ArgumentError, 'event_store can not be nil' if event_store.nil?
      raise ArgumentError, 'checkpoints_repo can not be nil' if checkpoints_repo.nil?
      @identifier, @event_store, @checkpoints_repo = identifier, event_store, checkpoints_repo
      @handlers = []
    end

    def add_handler handler
      @handlers << handler
    end

    # Pull all commits starting from the checkpoint for given identifier
    # and deliver each event of the commit to handlers that can handle it.
    # New checkpoint will be saved when all events are handled successfully for the commit.
    def pull
      checkpoint = @last_handled_checkpoint ||= @checkpoints_repo.get_checkpoint(@identifier)
      log.debug "Pulling commits for subscription '#{@identifier}' starting from checkpoint '#{checkpoint}'."
      @event_store.for_each_commit(checkpoint: checkpoint) do |commit|
        headers = commit.headers.dup
        headers[:$commit_timestamp] = commit.commit_timestamp
        @handlers.each { |handler|
          commit.events.each { |event|  
            handler.handle_message(event, headers) if handler.can_handle_message?(event)
          }
        }
        log.debug "Commit handled. Remembering checkpoint '#{commit.checkpoint}'."
        @checkpoints_repo.save_checkpoint(@identifier, commit.checkpoint)
        @last_handled_checkpoint = commit.checkpoint
      end
    end
  end
end