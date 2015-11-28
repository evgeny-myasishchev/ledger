module DummyEventStore
  class DummyPersistenceEngine < EventStore::Persistence::PersistenceEngine
    def supports_transactions?
      true
    end
  end
  
  class Base < EventStore::Base
    def initialize
      @persistence_engine = DummyPersistenceEngine.new
    end
    
    def dispatch_undispatched
    end
  
    def stream_exists?(stream_id)
      false
    end
  
    def open_stream(stream_id, min_revision: nil)
    end
  
    def transaction(&block)
      yield
    end
  
    def purge
    end
  end
  
  class DummyRepository < CommonDomain::Persistence::Repository
    attr_reader :event_store
    def initialize
      @event_store = DummyEventStore::Base.new
    end
    
    def exists?(aggregate_id)
    end
    
    def get_by_id(aggregate_class, id)
    end
    
    def save(aggregate, headers = {})
    end
  end
  
  class DummyRepositoryFactory < CommonDomain::PersistenceFactory
    attr_reader :repository
    
    def initialize
      @repository = DummyRepository.new
      super(nil, nil)
    end
    
    def create_repository
      @repository
    end
  end
  
  def create_dummy_repo_factory
    DummyRepositoryFactory.new
  end
end