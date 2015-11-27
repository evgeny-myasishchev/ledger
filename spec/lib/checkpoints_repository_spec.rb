describe CheckpointsRepository do
  shared_examples 'checkpoints repository' do
    it 'should return nil if no checkpoint for given identifier' do
      expect(subject.get_checkpoint('identifier-100')).to be_nil
      expect(subject.get_checkpoint('identifier-101')).to be_nil
    end

    it 'should return previously saved checkpoint' do
      subject.save_checkpoint('identifier-100', 100)
      subject.save_checkpoint('identifier-101', 101)
      expect(subject.get_checkpoint('identifier-100')).to eql 100
      expect(subject.get_checkpoint('identifier-101')).to eql 101
    end
  end

  describe CheckpointsRepository::InMemory do
    it_behaves_like 'checkpoints repository'
  end
end