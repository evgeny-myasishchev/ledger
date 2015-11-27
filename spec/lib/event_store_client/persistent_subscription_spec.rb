require 'rails_helper'


module EventStoreClientPersistentSubscriptionSpec
  DummyEvent = Struct.new(:name)

  class DummyHandler
    include CommonDomain::Messages::MessagesHandler

    attr_reader :handled_events
    attr_reader :handled_headers

    def initialize 
      @handled_events = []
      @handled_headers = []
    end

    on DummyEvent do |evt, headers|
      @handled_events << evt
      @handled_headers << headers
    end
  end

  describe EventStoreClient::PersistentSubscription do
    let(:event_store) {  
      EventStore.bootstrap do |with|
        with.log4r_logging
        with.in_memory_persistence
      end
    }
    let(:checkpoints_repo) { CheckpointsRepository::InMemory.new }
    let(:identifier) { "subscription-#{SecureRandom.hex(5)}" }
    subject { described_class.new identifier, event_store, checkpoints_repo }

    describe 'pull' do
      let(:handler1) { DummyHandler.new }
      let(:handler2) { DummyHandler.new }

      before do
        subject.add_handler handler1
        subject.add_handler handler2
      end

      it 'should deliver all events starting from begining to handlers' do
        evt11, evt12 = DummyEvent.new('evt11'), DummyEvent.new('evt12')
        commit1 = event_store.create_stream('stream-1')
          .add(evt11).add(evt12).commit_changes

        evt21, evt22 = DummyEvent.new('evt21'), DummyEvent.new('evt22')
        commit2 = event_store.create_stream('stream-2')
          .add(evt21).add(evt22).commit_changes

        subject.pull

        expect(handler1.handled_events).to eql [evt11, evt12, evt21, evt22]
        expect(handler2.handled_events).to eql [evt11, evt12, evt21, evt22]
      end

      it 'should deliver with headers' do
        headers1 = {header1: 'value-11', header2: 'value-12'}
        commit1 = event_store.create_stream('stream')
          .add(DummyEvent.new('evt')).add(DummyEvent.new('evt')).commit_changes(headers1)

        headers2 = {header1: 'value-21', header2: 'value-22'}
        commit2 = event_store.create_stream('stream')
          .add(DummyEvent.new('evt')).add(DummyEvent.new('evt')).commit_changes(headers2)

        subject.pull

        headers = [headers1, headers1, headers2, headers2]
        headers.each_index do |index|
          expect(handler1.handled_headers[index]).to include(headers[index])
          expect(handler2.handled_headers[index]).to include(headers[index])
        end        
      end

      it 'should add commit_timestamp to headers' do
        headers = {header1: 'value-11', header2: 'value-12'}
        commit1 = event_store.create_stream('stream').add(DummyEvent.new('evt')).commit_changes(headers)

        subject.pull

        expect(handler1.handled_headers[0]).to include(:$commit_timestamp => commit1.commit_timestamp)
        expect(handler2.handled_headers[0]).to include(:$commit_timestamp => commit1.commit_timestamp)
      end

      it 'should remember checkpoint of the last handled commit' do
        event_store.create_stream('stream-1').add(DummyEvent.new('evt11')).commit_changes
        event_store.create_stream('stream-2').add(DummyEvent.new('evt11')).commit_changes
        commit = event_store.create_stream('stream-3').add(DummyEvent.new('evt11')).commit_changes

        subject.pull

        expect(checkpoints_repo.get_checkpoint(identifier)).to eql commit.checkpoint
      end

      it 'should deliver handled events only' do
        evt11, evt12 = DummyEvent.new('evt11'), DummyEvent.new('evt12')
        commit1 = event_store.create_stream('stream-1')
          .add(double(:dummy_event_1)).add(double(:dummy_event_2))
          .add(evt11).add(evt12).commit_changes

        subject.pull

        expect(handler1.handled_events).to eql [evt11, evt12]
        expect(handler2.handled_events).to eql [evt11, evt12]
      end

      it 'should deliver all events starting from last known checkpoint to handlers' do
        event_store.create_stream('not-interested-0').add(DummyEvent.new('evt')).commit_changes
        skipped_commit = event_store.create_stream('not-interested-1').add(DummyEvent.new('evt')).commit_changes
        checkpoints_repo.save_checkpoint identifier, skipped_commit.checkpoint

        evt11, evt12 = DummyEvent.new('evt11'), DummyEvent.new('evt12')
        commit1 = event_store.create_stream('stream-1')
          .add(evt11).add(evt12).commit_changes

        evt21, evt22 = DummyEvent.new('evt21'), DummyEvent.new('evt22')
        commit2 = event_store.create_stream('stream-2')
          .add(evt21).add(evt22).commit_changes

        subject.pull

        expect(handler1.handled_events).to eql [evt11, evt12, evt21, evt22]
        expect(handler2.handled_events).to eql [evt11, evt12, evt21, evt22]
      end
    end
  end

end