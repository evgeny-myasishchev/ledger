require 'spec_helper'

describe Application::Commands::PendingTransactionCommands do
  let(:params) {
    {aggregate_id: 't-1', user: double(:user), amount: '100', date: 'free-date-string', tag_ids: ['t-1'], comment: 'transaction t-1', account_id: 'a-100', type_id: 'income' }
  }
  
  shared_examples :required_aggregate_id do
    it 'should validate presence of aggregate_id' do
      params[:aggregate_id] = nil
      subject = described_class.from_hash params
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::AdjustPendingTransaction do
    it_behaves_like :required_aggregate_id
  end
  
  describe described_class::ApprovePendingTransaction do
    it_behaves_like :required_aggregate_id
  end
  
  describe described_class::AdjustAndApprovePendingTransaction do
    it_behaves_like :required_aggregate_id
  end
  
  describe described_class::RejectPendingTransaction do
    it_behaves_like :required_aggregate_id
  end
end