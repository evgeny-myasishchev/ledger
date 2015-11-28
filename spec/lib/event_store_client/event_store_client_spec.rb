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
        allow(subject).to receive(:build_subscription) { subscription }
      end

      it 'should derive identifier from subscription class' do
        expect(subject).to receive(:build_subscription).with('EventStoreClientSpec::DummyHandler') { subscription }
        subject.subscribe_handler DummyHandler.new
      end

      it 'should add subscription handler' do
        handler = DummyHandler.new
        expect(subscription).to receive(:add_handler).with(handler)
        subject.subscribe_handler handler
      end
      
      it 'should allow grouping subscriptions' do
        allow(subject).to receive(:build_subscription).and_call_original
        
        default1, default2 = DummyHandler.new, DummyHandler.new
        grp11, grp12 = DummyHandler.new, DummyHandler.new
        grp21, grp22 = DummyHandler.new, DummyHandler.new
        subject.subscribe_handler default1
        subject.subscribe_handler default2
        subject.subscribe_handler grp11, group: :grp1
        subject.subscribe_handler grp12, group: :grp1
        subject.subscribe_handler grp21, group: :grp2
        subject.subscribe_handler grp22, group: :grp2
        
        expect(subject.subscriptions.map(&:handlers).flatten).to eql [default1, default2, grp11, grp12, grp21, grp22]
        expect(subject.subscribed_handlers).to eql [default1, default2, grp11, grp12, grp21, grp22]
        expect(subject.subscriptions(group: :grp1).map(&:handlers).flatten).to eql [grp11, grp12]
        expect(subject.subscribed_handlers(group: :grp1)).to eql [grp11, grp12]
        expect(subject.subscriptions(group: :grp2).map(&:handlers).flatten).to eql [grp21, grp22]
        expect(subject.subscribed_handlers(group: :grp2)).to eql [grp21, grp22]
      end
    end

    describe 'pull_subscriptions' do
      let(:subscription1) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }
      let(:subscription2) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }
      let(:subscription3) { instance_double(EventStoreClient::PersistentSubscription, add_handler: nil) }

      it 'should pull each subscription' do
        allow(subject).to receive(:build_subscription).and_return(subscription1, subscription2, subscription3)
        subject.subscribe_handler DummyHandler.new
        subject.subscribe_handler DummyHandler.new
        subject.subscribe_handler DummyHandler.new
        
        expect(subscription1).to receive(:pull)
        expect(subscription2).to receive(:pull)
        expect(subscription3).to receive(:pull)
        subject.pull_subscriptions
      end
      
      it 'should pull specified groups only' do
        allow(subject).to receive(:build_subscription).and_return(subscription1, subscription2, subscription3)
        subject.subscribe_handler DummyHandler.new
        subject.subscribe_handler DummyHandler.new, group: :group1
        subject.subscribe_handler DummyHandler.new, group: :group1
        
        expect(subscription1).not_to receive(:pull)
        expect(subscription2).to receive(:pull)
        expect(subscription3).to receive(:pull)
        subject.pull_subscriptions group: :group1
      end
    end
  end
end