require 'rails_helper'

describe Application::Commands do
  describe described_class::AccountCommands do
    describe described_class::AdjustAmount do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', amount: '100.5'
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.amount).to eql('100.5')
      end
    
      it "should validate presentce of transaction_id and amount" do
        subject = described_class.new transaction_id: '', amount: ''
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:amount]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustTags do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', tag_ids: [100, 200]
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.tag_ids).to eql([100, 200])
      end
    
      it "should validate presentce of transaction_id" do
        subject = described_class.new transaction_id: nil, tag_ids: []
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustDate do
      it "should initialize the command from params" do
        date = DateTime.new
        subject = described_class.new transaction_id: 't-100', date: date
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.date).to eql(date)
      end
    
      it "should validate presentce of transaction_id and date" do
        subject = described_class.new transaction_id: nil, date: nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:date]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustComment do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', comment: 'New comment'
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.comment).to eql('New comment')
      end
    
      it "should validate presentce of transaction_id" do
        subject = described_class.new transaction_id: nil, comment: nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      end
    end
    
    describe described_class::ConvertTransactionType do
      it "should initialize the command from params" do
        subject = described_class.new account_id: 'a-100', transaction_id: 't-100', type_id: 101
        expect(subject.account_id).to eql('a-100')
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.type_id).to eql(101)
      end
    
      it "should validate presentce of transaction_id and type_id" do
        subject = described_class.new account_id: nil, transaction_id: nil, type_id: nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:account_id]).to eql ["can't be blank"]
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:type_id]).to eql ["can't be blank"]
      end
    end
  end
end