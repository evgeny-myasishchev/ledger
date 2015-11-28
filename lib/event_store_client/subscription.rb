# Base interface for event store subscriptions
class EventStoreClient::Subscription
  include Loggable
  
  attr_reader :handlers
  
  def initialize
    @handlers = []
  end
  
  # Adds event handler that will handle pulled events
  def add_handler handler
    @handlers << handler
  end
  
  def pull
    raise 'Not implemented'
  end
end