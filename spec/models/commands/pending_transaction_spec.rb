require 'spec_helper'

describe Application::Commands::PendingTransactionCommands do
  let(:params) do
    { id: 't-1', user: double(:user), amount: '100', date: 'free-date-string',
      tag_ids: ['t-1'], comment: 'transaction t-1', account_id: 'a-100', type_id: 'income' }
  end

  shared_examples :required_id_attribute do
    it 'should validate presence of id' do
      params[:id] = nil
      subject = described_class.from_hash params
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:id]).to eql ["can't be blank"]
    end
  end

  describe described_class::AdjustPendingTransaction do
    it_behaves_like :required_id_attribute
  end

  describe described_class::ApprovePendingTransaction do
    it_behaves_like :required_id_attribute
  end

  describe described_class::AdjustAndApprovePendingTransaction do
    it_behaves_like :required_id_attribute
  end

  describe described_class::AdjustAndApprovePendingTransferTransaction do
    it_behaves_like :required_id_attribute

    it 'should validate presence of the receiving_account_id and amount_received attributes' do
      subject = described_class.from_hash params
      expect(subject).not_to be_valid
      expect(subject.errors[:receiving_account_id]).to eql ["can't be blank"]
      expect(subject.errors[:amount_received]).to eql ["can't be blank"]

      params[:receiving_account_id] = 'account-100'
      params[:amount_received] = 100
      subject = described_class.from_hash params
      expect(subject).to be_valid
    end
  end

  describe described_class::RejectPendingTransaction do
    it_behaves_like :required_id_attribute
  end

  describe described_class::RestorePendingTransaction do
    it_behaves_like :required_id_attribute
  end
end
