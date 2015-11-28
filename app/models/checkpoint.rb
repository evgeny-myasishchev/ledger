class Checkpoint < ActiveRecord::Base
  class Repository < CheckpointsRepository
    def get_checkpoint(identifier)
      Checkpoint.where(identifier: identifier).pluck(:checkpoint_number).first
    end
    
    def save_checkpoint(identifier, checkpoint)
      Checkpoint.find_or_initialize_by(identifier: identifier).update(checkpoint_number: checkpoint)
    end
  end
end
