require 'rails_helper'

describe Application::Commands::LedgerCommands do
  shared_examples_for 'a command with required ledger_id and account_id' do
    it "should vlaidate presence ledger_id and account_id" do
      subject = described_class.from_hash ledger_id: nil, account_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:account_id]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::CreateNewAccount do
    it "should vlaidate presence of all attributes" do
      subject = described_class.from_hash ledger_id: nil, account_id: nil, name: nil, initial_balance: nil, currency_code: nil, unit: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:account_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
      expect(subject.errors[:initial_balance]).to eql ["can't be blank"]
      expect(subject.errors[:currency_code]).to eql ["can't be blank"]
    end
  end
  
  describe described_class::CloseAccount do
    it_behaves_like 'a command with required ledger_id and account_id'
  end
  
  describe described_class::ReopenAccount do
    it_behaves_like 'a command with required ledger_id and account_id'
  end
  
  describe described_class::RemoveAccount do
    it_behaves_like 'a command with required ledger_id and account_id'
  end
  
  describe described_class::CreateTag do
    it "shold validate presence of aggregate_id and name" do
      subject = described_class.from_hash ledger_id: nil, name: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', name: 'tag-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.name).to eql 'tag-1'
    end
  end
  
  describe described_class::RenameTag do
    it "shold validate presence of aggregate_id, tag_id and name" do
      subject = described_class.from_hash ledger_id: nil, tag_id: nil, name: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:tag_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', tag_id: 't-1', name: 'tag-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.tag_id).to eql 't-1'
      expect(subject.name).to eql 'tag-1'
    end
  end
  
  describe described_class::RemoveTag do
    it "shold validate presence of aggregate_id, tag_id" do
      subject = described_class.from_hash ledger_id: nil, tag_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:tag_id]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', tag_id: 't-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.tag_id).to eql 't-1'
    end
  end
  
  describe described_class::CreateCategory do
    it "shold validate presence of aggregate_id and name" do
      subject = described_class.from_hash ledger_id: nil, name: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', name: 'category-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.name).to eql 'category-1'
    end
  end
  
  describe described_class::RenameCategory do
    it "shold validate presence of aggregate_id, category_id and name" do
      subject = described_class.from_hash ledger_id: nil, category_id: nil, name: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:category_id]).to eql ["can't be blank"]
      expect(subject.errors[:name]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', category_id: 'c-1', name: 'category-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.category_id).to eql 'c-1'
      expect(subject.name).to eql 'category-1'
    end
  end
  
  describe described_class::RemoveCategory do
    it "shold validate presence of aggregate_id, category_id" do
      subject = described_class.from_hash ledger_id: nil, category_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:category_id]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', category_id: 'c-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.category_id).to eql 'c-1'
    end
  end
  
  describe described_class::SetAccountCategory do
    it "shold validate presence of ledger_id, account_id, category_id" do
      subject = described_class.from_hash ledger_id: nil, account_id: nil, category_id: nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:ledger_id]).to eql ["can't be blank"]
      expect(subject.errors[:account_id]).to eql ["can't be blank"]
      expect(subject.errors[:category_id]).to eql ["can't be blank"]
      subject = described_class.from_hash ledger_id: 'l-1', account_id: 'a-1', category_id: 'c-1'
      expect(subject.valid?).to be_truthy
      expect(subject.ledger_id).to eql 'l-1'
      expect(subject.account_id).to eql 'a-1'
      expect(subject.category_id).to eql 'c-1'
    end
  end
end