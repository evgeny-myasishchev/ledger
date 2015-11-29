require 'rails_helper'

describe EventStoreClient::ConcurrentSubscription do
  let(:target) { instance_double(EventStoreClient::PersistentSubscription) }
  subject { described_class.new(target) }

  it 'should delegate add_handler and handlers to target' do
    handler = double(:handler)
    handlers = double(:handlers)
    expect(target).to receive(:add_handler).with(handler)
    expect(target).to receive(:handlers) { handlers }
    subject.add_handler handler
    expect(subject.handlers).to be handlers
  end

  describe 'pull' do
    it 'should schedule pulling of a target subscription in a separate thread' do
    end
  end
end