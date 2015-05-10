module DummyEventStore
  class DummyPersistenceEngine < EventStore::Persistence::PersistenceEngine
    def supports_transactions?
      true
    end
  end
  
  class DummyTransactionContext < EventStore::Persistence::PersistenceEngine::TransactionContext
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
      yield DummyTransactionContext.new
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
    
    def save(aggregate, headers = {}, transaction = nil)
    end
  end
  
  class DummyRepositoryFactory < CommonDomain::Persistence::EventStore::RepositoryFactory
    attr_reader :repository
    
    def initialize
      @repository = DummyRepository.new
    end
    
    def create_repository
      @repository
    end
  end
  
  def create_dummy_repo_factory
    DummyRepositoryFactory.new
  end
  
  def dummy_transaction_context
    DummyTransactionContext.new
  end
    
  def with_dummy_transaction_context
    kind_of(DummyTransactionContext)
  end
end