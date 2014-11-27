require 'rails_helper'

module SnapshotsSpec
  module CD
    include CommonDomain::Persistence::Snapshots
  end
  
  RSpec.describe Snapshot, :type => :model do
    describe 'self.add' do
      it 'should insert new snapshot with given data' do
        Snapshot.add CD::Snapshot.new 'snapshot-1', 100, {key1: 'value-1', key2: 'value-2'}
        snapshot = Snapshot.find_by aggregate_id: 'snapshot-1'
        expect(snapshot).not_to be_nil
        expect(snapshot.version).to eql 100
        expect(Snapshot.deserialize_data(snapshot.data)).to eql({key1: 'value-1', key2: 'value-2'})
      end
      
      it 'should override existing snapshot' do
        Snapshot.add CD::Snapshot.new 'snapshot-1', 100, {key1: 'value-1', key2: 'value-2'}
        Snapshot.add CD::Snapshot.new 'snapshot-1', 101, {key3: 'value-3', key4: 'value-4'}
        expect(Snapshot.count(aggregate_id: 'snapshot-1')).to eql 1
        snapshot = Snapshot.find_by aggregate_id: 'snapshot-1'
        expect(snapshot).not_to be_nil
        expect(snapshot.version).to eql 101
        expect(Snapshot.deserialize_data(snapshot.data)).to eql({key3: 'value-3', key4: 'value-4'})
      end
    end
  end
  
  describe 'self.get' do
    it 'should return nill if no snapshot' do
      expect(Snapshot.get('snapshot-1')).to be_nil
    end
    
    it 'should return the snapshot if present' do
      Snapshot.create! aggregate_id: 'snapshot-1', version: 100, data: Snapshot.serialize_data({key1: 'value-1', key2: 'value-2'})
      snapshot = Snapshot.get('snapshot-1')
      expect(snapshot).not_to be_nil
      expect(snapshot).to be_an_instance_of CD::Snapshot
      expect(snapshot.version).to eql 100
      expect(snapshot.data).to eql({key1: 'value-1', key2: 'value-2'})
    end
  end
end