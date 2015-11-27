require 'rails_helper'

module EventStoreClientSpec

  class DummyHandler
  end


  describe EventStoreClient do
    let(:event_store) {  
      EventStore.bootstrap do |with|
        with.log4r_logging
        with.in_memory_persistence
      end
    }
    let(:checkpoints_repo) { CheckpointsRepository::InMemory.new }

    subject { described_class.new(event_store, checkpoints_repo) }

    describe 'subscribe_handler' do    
      let(:subscription) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }
      before do
        allow(described_class).to receive(:build_subscription) { subscription }
      end

      it 'should derive identifier from subscription class' do
        expect(described_class).to receive(:build_subscription).with('EventStoreClientSpec::DummyHandler') { subscription }        
        subject.subscribe_handler DummyHandler.new
      end

      it 'should add subscription handler' do
        handler = DummyHandler.new
        expect(subscription).to receive(:add_handler).with(handler)
        subject.subscribe_handler handler
      end
    end

    describe 'pull_subscriptions' do
      let(:subscription1) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }
      let(:subscription2) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }
      let(:subscription3) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }

      before do
        allow(described_class).to receive(:build_subscription).and_return(subscription1, subscription2, subscription3)
        subject.subscribe_handler DummyHandler.new
        subject.subscribe_handler DummyHandler.new
        subject.subscribe_handler DummyHandler.new
      end

      it 'should pull each subscription' do
        expect(subscription1).to receive(:pull)
        expect(subscription2).to receive(:pull)
        expect(subscription3).to receive(:pull)
        subject.pull_subscriptions
      end
    end
  end
end