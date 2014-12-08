class Snapshot < ActiveRecord::Base
  
  class << self
    
    def get aggregate_id
      snapshot = find_by aggregate_id: aggregate_id
      return nil if snapshot.nil?
      CommonDomain::Persistence::Snapshots::Snapshot.new snapshot.aggregate_id, snapshot.version, deserialize_data(snapshot.data)
    end
  
    def add snapshot
      rec = find_or_initialize_by(aggregate_id: snapshot.id)
      rec.version = snapshot.version
      rec.data = serialize_data(snapshot.data)
      rec.save!
    end
    
    def serialize_data data
      serializer.serialize data
    end
    
    def deserialize_data data
      serializer.deserialize data
    end
    
    private def serializer
      @serializer ||= EventStore::Persistence::Serializers::GzipSerializer.new(EventStore::Persistence::Serializers::MarshalSerializer.new)
    end
  end
end
