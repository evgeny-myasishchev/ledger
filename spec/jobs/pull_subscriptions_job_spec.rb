require 'rails_helper'

RSpec.describe PullSubscriptionsJob, type: :job do
  let(:event_store_client) { instance_double(EventStoreClient) }
  
  before do
    allow(Rails.application).to receive(:event_store_client) { event_store_client }
  end
  
  it 'should pull subscriptions' do
    expect(event_store_client).to receive(:pull_subscriptions)
    subject.perform
  end
  
  it 'should pull specified groups only' do
    expect(event_store_client).to receive(:pull_subscriptions).with(group: :group100)
    subject.perform(group: :group100)
  end
end
