require 'rails_helper'

RSpec.describe Projections::Transaction, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:p) { Projections }
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expence_id) { Domain::Transaction::ExpenceTypeId }
  include AccountHelpers::P
  
  describe "self.get_account_transactions" do
    let(:user) { 
      u = User.new
      u.id = 2233
      u
    }
    let(:date) { DateTime.now }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }
    before(:each) do
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expence_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      
      allow(p::Account).to receive(:ensure_authorized!) { account }
    end
    
    it "should check if the user is authorized" do
      described_class.get_account_transactions user, account.id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.id, user)
    end
    
    it "should get all transactions of the user" do
      transactions = described_class.get_account_transactions user, account.id
      expect(transactions.length).to eql 3
      t1 = transactions.detect { |t| t.transaction_id == 't-1' }
      expect(t1.attributes).to eql('id' => t1.id,
        'transaction_id' => 't-1',
        'type_id' => income_id,
        'ammount' => 10523,
        'tag_ids' => '{t-1},{t-2}',
        'comment' => 'Comment 101',
        'date' => (date - 100).to_time)
      expect(transactions.detect { |t| t.transaction_id == 't-2' }).not_to be_nil
      expect(transactions.detect { |t| t.transaction_id == 't-3' }).not_to be_nil
    end
    
    it "orders transactions by date descending" do
      transactions = described_class.get_account_transactions user, account.id
      expect(transactions[0].transaction_id).to eql 't-1'
      expect(transactions[1].transaction_id).to eql 't-2'
      expect(transactions[2].transaction_id).to eql 't-3'
    end
  end
  
  describe "add_tag" do
    subject { p::Transaction.new }
    before(:each) do
      subject.add_tag 100
      subject.add_tag 110
      subject.add_tag 120
    end
    
    it "should add a tag wrapped in curly braces" do
      expect(subject.tag_ids).to eql '{100},{110},{120}'
    end
    
    it "should mark the tag_ids as changed" do
      expect(subject.tag_ids_changed?).to be_truthy
    end
    
    it "should not add the tag_id if already present" do
      subject.changed_attributes.clear
      subject.add_tag 100
      expect(subject.tag_ids).to eql('{100},{110},{120}')
      expect(subject.tag_ids_changed?).to be_falsey
    end
  end
  
  describe "on TransactionReported" do
    it "should record the transaction" do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', income_id, 10523, date1, ['t-1', 't-2'], 'Comment 100'
      subject.handle_message e::TransactionReported.new 'account-1', 't-2', expence_id, 2000, date2, ['t-3', 't-4'], 'Comment 101'
      
      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(income_id)
      expect(t1.ammount).to eql(10523)
      expect(t1.tag_ids).to eql '{t-1},{t-2}'
      expect(t1.comment).to eql 'Comment 100'
      expect(t1.date.to_datetime).to eql date1.utc
      
      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2.account_id).to eql('account-1')
      expect(t2.type_id).to eql(expence_id)
      expect(t2.ammount).to eql(2000)
      expect(t2.tag_ids).to eql '{t-3},{t-4}'
      expect(t2.comment).to eql 'Comment 101'
      expect(t2.date.to_datetime).to eql date2.utc
    end
  end
end
