require 'rails_helper'

RSpec.describe Checkpoint, type: :model do
  describe Checkpoint::Repository do
    it_behaves_like 'checkpoints repository'
  end
end
