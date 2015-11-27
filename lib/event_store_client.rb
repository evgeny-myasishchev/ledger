class EventStoreClient
  def initialize(event_store, checkpoints_repo)
  end

  def subscribe_handler handler
  end

  def pull_subscriptions
  end

  #
  # The subscription will persist checkpoint of last commit that has been successfully handled by all handlers.
  # It does not automatically know if new commits are available so pull must be called explicitly.
  #
  class PersistentSubscription
    def initialize(identifier, event_store, checkpoints_repo)
      @identifier, @event_store, @checkpoints_repo = identifier, event_store, checkpoints_repo
    end

    def add_handler handler
    end

    # Pull all commits starting from the checkpoint for given identifier
    # and deliver each event of the commit to handlers that can handle it.
    # New checkpoint will be saved when all events are handled successfully for the commit.
    def pull
    end
  end
end