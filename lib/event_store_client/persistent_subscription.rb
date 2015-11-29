#
# The subscription will persist checkpoint of last commit that has been successfully handled by all handlers.
# It does not automatically know if new commits are available so pull must be called explicitly.
#
class EventStoreClient::PersistentSubscription < EventStoreClient::Subscription

  attr_reader :identifier

  def initialize(identifier, event_store, checkpoints_repo)
    raise ArgumentError, 'identifier can not be nil' if identifier.nil?
    raise ArgumentError, 'event_store can not be nil' if event_store.nil?
    raise ArgumentError, 'checkpoints_repo can not be nil' if checkpoints_repo.nil?
    @identifier, @event_store, @checkpoints_repo = identifier, event_store, checkpoints_repo
    super()
  end

  # Pull all commits starting from the checkpoint for given identifier
  # and deliver each event of the commit to handlers that can handle it.
  # New checkpoint will be saved when all events are handled successfully for the commit.
  def pull
    checkpoint = @last_handled_checkpoint ||= @checkpoints_repo.get_checkpoint(@identifier)
    logger.debug "Pulling commits for subscription '#{@identifier}' starting from checkpoint '#{checkpoint}'."
    @event_store.for_each_commit(checkpoint: checkpoint) do |commit|
      headers = commit.headers.dup
      headers[:$commit_timestamp] = commit.commit_timestamp
      @handlers.each { |handler|
        commit.events.each { |event|
          handler.handle_message(event, headers) if handler.can_handle_message?(event)
        }
      }
      logger.debug "Commit handled. Remembering checkpoint '#{commit.checkpoint}'."
      @checkpoints_repo.save_checkpoint(@identifier, commit.checkpoint)
      @last_handled_checkpoint = commit.checkpoint
    end
  end
end