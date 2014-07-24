require 'rails_helper'

RSpec.describe Projections::Transaction, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:p) { Projections }
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expence_id) { Domain::Transaction::ExpenceTypeId }
  include AccountHelpers::P
  
  describe "get_transfer_counterpart" do
    def new_transfer id, &block
      t = p::Transaction.new transaction_id: id, account_id: 'a-10', type_id: 1, ammount: 10, is_transfer: true
      yield(t)
      t.save!
      t
    end
    
    let(:sending) { new_transfer 't-1' do |t|
      t.sending_transaction_id = t.transaction_id
    end}
    let(:receiving) { new_transfer 't-2' do |t|
      t.receiving_transaction_id = t.transaction_id
      t.sending_transaction_id = 't-1'
    end}
    
    before(:each) do
      # Doing so to have them initialized
      sending
      receiving
    end
    
    it "should fail if the transaction is not transfer" do
      t = p::Transaction.create! transaction_id: 't-3', account_id: 'a-10', type_id: 1, ammount: 10
      expect { t.get_transfer_counterpart }.to raise_error "Transaction 't-3' is not involved in transfer."
    end
    
    it "should return receiving transaction if current is sending" do
      expect(sending.get_transfer_counterpart).to eql receiving
    end
    
    it "should return sending transaction if current is receiving" do
      expect(receiving.get_transfer_counterpart).to eql sending
    end
  end
  
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
      described_class.get_account_transactions user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end
    
    it "should get all transactions of the user" do
      transactions = described_class.get_account_transactions user, account.aggregate_id
      expect(transactions.length).to eql 3
      t1 = transactions.detect { |t| t.transaction_id == 't-1' }
      expect(t1.attributes).to eql('id' => t1.id,
        'transaction_id' => 't-1',
        'type_id' => income_id,
        'ammount' => 10523,
        'tag_ids' => '{t-1},{t-2}',
        'comment' => 'Comment 101',
        'date' => (date - 100).to_time,
        'is_transfer' => false,
        'sending_account_id' => nil,
        'sending_transaction_id' => nil,
        'receiving_account_id' => nil,
        'receiving_transaction_id' => nil)
      expect(transactions.detect { |t| t.transaction_id == 't-2' }).not_to be_nil
      expect(transactions.detect { |t| t.transaction_id == 't-3' }).not_to be_nil
    end
    
    it "orders transactions by date descending" do
      transactions = described_class.get_account_transactions user, account.aggregate_id
      expect(transactions[0].transaction_id).to eql 't-1'
      expect(transactions[1].transaction_id).to eql 't-2'
      expect(transactions[2].transaction_id).to eql 't-3'
    end
    
    it "should include transfer related attributes" do
      t1 = p::Transaction.find_by_transaction_id 't-1'
      t1.is_transfer = true
      t1.sending_account_id = 'sa-1'
      t1.sending_transaction_id = 'st-1'
      t1.receiving_account_id = 'ra-2'
      t1.receiving_transaction_id = 'rt-2'
      t1.save!
      
      transactions = described_class.get_account_transactions user, account.aggregate_id
      t1_rec = transactions.detect { |t| t.transaction_id == 't-1' }
      expect(t1_rec['is_transfer']).to be_truthy
      expect(t1_rec['sending_account_id']).to eql('sa-1')
      expect(t1_rec['sending_transaction_id']).to eql('st-1')
      expect(t1_rec['receiving_account_id']).to eql('ra-2')
      expect(t1_rec['receiving_transaction_id']).to eql('rt-2')
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
  
  describe "transfer" do
    let(:date) { DateTime.now - 100 }
    let(:t1) { described_class.find_by_transaction_id 't-1' }
    let(:t2) { described_class.find_by_transaction_id 't-2' }
    before(:each) do
      subject.handle_message e::TransferSent.new 'account-1', 't-1', 'account-2', 10523, date, ['t-1', 't-2'], 'Comment 100'
      subject.handle_message e::TransferReceived.new 'account-2', 't-2', 'account-1', 't-1', 10523, date, ['t-1', 't-2'], 'Comment 100'
    end

    describe "on TransferSent" do
      it "should record the transaction as expence" do
        expect(t1.account_id).to eql('account-1')
        expect(t1.transaction_id).to eql('t-1')
        expect(t1.type_id).to eql(expence_id)
        expect(t1.ammount).to eql(10523)
        expect(t1.tag_ids).to eql '{t-1},{t-2}'
        expect(t1.comment).to eql 'Comment 100'
        expect(t1.date.to_datetime).to eql date.utc
      end
    
      it "should record transfer related attributes" do
        expect(t1.is_transfer).to be_truthy
        expect(t1.sending_account_id).to eql('account-1')
        expect(t1.sending_transaction_id).to eql('t-1')
        expect(t1.receiving_account_id).to eql('account-2')
      end
    end
    
    describe "on TransferReceived" do
      it "should record the transaction as income" do
        expect(t2.account_id).to eql('account-2')
        expect(t2.transaction_id).to eql('t-2')
        expect(t2.type_id).to eql(income_id)
        expect(t2.ammount).to eql(10523)
        expect(t2.tag_ids).to eql '{t-1},{t-2}'
        expect(t2.comment).to eql 'Comment 100'
        expect(t2.date.to_datetime).to eql date.utc
      end
    
      it "should record transfer related attributes" do
        expect(t2.is_transfer).to be_truthy
        expect(t2.sending_account_id).to eql('account-1')
        expect(t2.sending_transaction_id).to eql('t-1')
        expect(t2.receiving_account_id).to eql('account-2')
        expect(t2.receiving_transaction_id).to eql('t-2')
      end
    end
  end
  
  describe "adjustments" do
    let(:date) { DateTime.now - 100 }
    let(:t1) { p::Transaction.find_by_transaction_id 't-1' }
    before(:each) do
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', expence_id, 2000, date, ['t-1'], 'Comment 1'
    end
    
    it "should update comment on TransactionCommentAdjusted" do
      subject.handle_message e::TransactionCommentAdjusted.new 'account-1', 't-1', 'New comment 1'
      expect(t1.comment).to eql 'New comment 1'
    end
  end
end
