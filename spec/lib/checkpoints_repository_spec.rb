require 'rails_helper'

describe CheckpointsRepository do
  describe CheckpointsRepository::InMemory do
    it_behaves_like 'checkpoints repository'
  end
end