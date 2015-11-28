class PullSubscriptionsJob < ActiveJob::Base
  queue_as :default

  def perform(group: nil)
    event_store_client.pull_subscriptions(group: group)
  end
  
  private def event_store_client
    Rails.application.event_store_client
  end
end
