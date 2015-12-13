require 'rails_helper'

RSpec.describe Checkpoint, type: :model do
  describe Checkpoint::Repository do
    it_behaves_like 'checkpoints repository'

    it 'should remember saved checkpoint and return it without accessing the underlying storage' do
      subject.save_checkpoint('cp-100', 10001)
      subject.save_checkpoint('cp-102', 10002)

      Checkpoint.find_by(identifier: 'cp-100').update(checkpoint_number: 3112)
      Checkpoint.find_by(identifier: 'cp-102').update(checkpoint_number: 3231)

      expect(subject.get_checkpoint('cp-100')).to eql 10001
      expect(subject.get_checkpoint('cp-102')).to eql 10002
    end
  end
end
