class Checkpoint < ActiveRecord::Base
  class Repository < CheckpointsRepository
    def initialize
      @checkpoints = Concurrent::Map.new
    end

    def get_checkpoint(identifier)
      @checkpoints.fetch(identifier, Checkpoint.where(identifier: identifier).pluck(:checkpoint_number).first)
    end
    
    def save_checkpoint(identifier, checkpoint)
      Checkpoint.find_or_initialize_by(identifier: identifier).update(checkpoint_number: checkpoint)
      @checkpoints.put identifier, checkpoint
    end
  end
end
