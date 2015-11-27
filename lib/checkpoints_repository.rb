class CheckpointsRepository
  # Retrieves checkpoint for given identifier. Returns nil if no checkpoint.
  def get_checkpoint(identifier)
    raise 'Not implemented'
  end

  # Saves the checkpoint for given identifier.
  def save_checkpoint(identifier, checkpoint)
    raise 'Not implemented'
  end

  # In Memory checkpoints repository. 
  # To be used for testing purposes.
  class InMemory < CheckpointsRepository
    def initialize
      @store = {}
    end

    def get_checkpoint(identifier) 
      @store[identifier]
    end

    def save_checkpoint(identifier, checkpoint)
      @store[identifier] = checkpoint
    end
  end
  
  # TODO: Implement AR based repo
end