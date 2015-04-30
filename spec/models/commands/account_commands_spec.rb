require 'spec_helper'

describe Application::Commands::AccountCommands do
  describe described_class::RemoveTransaction do
    it "should initialize the command from params" do
      subject = described_class.new transaction_id: 't-100'
      expect(subject.transaction_id).to eql('t-100')
    end
  
    it "should validate presentce of transaction_id" do
      subject = described_class.new transaction_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::MoveTransaction do
    it "should initialize the command from params" do
      subject = described_class.new transaction_id: 't-100', target_account_id: 'account-223'
      expect(subject.transaction_id).to eql('t-100')
      expect(subject.target_account_id).to eql('account-223')
    end
  
    it "should validate presence of transaction_id and target_account_id" do
      subject = described_class.new transaction_id: nil, target_account_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      expect(subject.errors[:target_account_id]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::RenameAccount do
    it "should initialize the command from params" do
      subject = described_class.new aggregate_id: 'a-100', name: 'New account 100'
      expect(subject.aggregate_id).to eql('a-100')
      expect(subject.name).to eql('New account 100')
      expect(subject.valid?).to be_truthy
    end
    
    it "should validate presence of all attributes" do
      subject = described_class.new aggregate_id: nil, name: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::SetAccountUnit do
    it "should initialize the command from params" do
      subject = described_class.new aggregate_id: 'a-100', unit: 'oz'
      expect(subject.aggregate_id).to eql('a-100')
      expect(subject.unit).to eql('oz')
      expect(subject.valid?).to be_truthy
    end
    
    it "should validate presence aggregate_id" do
      subject = described_class.new aggregate_id: nil, unit: 'oz'
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
    end
  end
end