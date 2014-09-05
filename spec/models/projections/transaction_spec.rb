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
  
  describe "self.get_account_home_data" do
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
      described_class.get_account_home_data user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end
    
    it "should include account balance" do
      account.balance = 2233119
      account.save!
      data = described_class.get_account_home_data user, account.aggregate_id
      expect(data[:account_balance]).to eql(2233119)
    end
    
    it "should get all transactions of the user" do
      transactions = described_class.get_account_home_data(user, account.aggregate_id)[:transactions]
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
      transactions = described_class.get_account_home_data(user, account.aggregate_id)[:transactions]
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
      
      transactions = described_class.get_account_home_data(user, account.aggregate_id)[:transactions]
      t1_rec = transactions.detect { |t| t.transaction_id == 't-1' }
      expect(t1_rec['is_transfer']).to be_truthy
      expect(t1_rec['sending_account_id']).to eql('sa-1')
      expect(t1_rec['sending_transaction_id']).to eql('st-1')
      expect(t1_rec['receiving_account_id']).to eql('ra-2')
      expect(t1_rec['receiving_transaction_id']).to eql('rt-2')
    end
    
    it "should paginate and include pagination info" do
      account_2 = create_account_projection! 'account-2', authorized_user_ids: '{2233}'
      allow(p::Account).to receive(:ensure_authorized!) { account_2 }
      20.times do |time|
        subject.handle_message e::TransactionReported.new account_2.aggregate_id, "a2-t-#{time}", expence_id, 2000, DateTime.new, [], ''
      end
      data = described_class.get_account_home_data(user, account_2.aggregate_id, limit: 5)
      expect(data[:transactions_total]).to eql 20
      expect(data[:transactions_limit]).to eql 5
      expect(data[:transactions].length).to eql 5
    end
  end
  
  describe "self.get_range" do
    let(:user) { User.new id: 2233 }
    let(:date) { DateTime.now }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }
    before(:each) do
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expence_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      
      allow(p::Account).to receive(:ensure_authorized!) { account }
    end
    
    it "should check if the user is authorized" do
      described_class.get_account_home_data user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end
    
    it "should get transactions of the user" do
      transactions = described_class.get_range(user, account.aggregate_id)
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
      transactions = described_class.get_range(user, account.aggregate_id)
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
      
      transactions = described_class.get_range(user, account.aggregate_id)
      t1_rec = transactions.detect { |t| t.transaction_id == 't-1' }
      expect(t1_rec['is_transfer']).to be_truthy
      expect(t1_rec['sending_account_id']).to eql('sa-1')
      expect(t1_rec['sending_transaction_id']).to eql('st-1')
      expect(t1_rec['receiving_account_id']).to eql('ra-2')
      expect(t1_rec['receiving_transaction_id']).to eql('rt-2')
    end
    
    it "should track limit and offset" do
      account_2 = create_account_projection! 'account-2', authorized_user_ids: '{2233}'
      allow(p::Account).to receive(:ensure_authorized!) { account_2 }
      20.times do |time|
        subject.handle_message e::TransactionReported.new account_2.aggregate_id, "a2-t-#{time}", expence_id, 2000, DateTime.new, [], ''
      end
      transactions = described_class.get_range(user, account_2.aggregate_id, limit: 5, offset: 10)
      expect(transactions.length).to eql 5
      expect(transactions[0]['transaction_id']).to eql('a2-t-10')
      expect(transactions[4]['transaction_id']).to eql('a2-t-14')
    end
  end
  
  describe 'self.search' do
    let(:date) { DateTime.now }
    let(:user) { User.new id: 2233 }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }
    
    before(:each) do
      allow(p::Account).to receive(:ensure_authorized!) { account }
      
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expence_id, 0, date - 110, ['tag-3'], ''
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', expence_id, 0, date, ['tag-1'], ''
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expence_id, 0, date - 100, ['tag-2'], ''
    end
    
    it "should check if the user is authorized" do
      described_class.search user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end
    
    it 'should have required attributes' do
      result = described_class.search user, account.aggregate_id
      expect_required_attributes result.first
    end
    
    it 'should order transactions by date descending' do
      transactions = described_class.search user, account.aggregate_id
      expect(transactions[0].transaction_id).to eql 't-1'
      expect(transactions[1].transaction_id).to eql 't-2'
      expect(transactions[2].transaction_id).to eql 't-3'
    end
    
    it 'should filter by tag_ids' do
      result = described_class.search user, account.aggregate_id, criteria: {tag_ids: ['tag-1', 'tag-2']}
      expect(result.length).to eql 2
      expect(result[0]).to eql described_class.find_by transaction_id: 't-1'
      expect(result[1]).to eql described_class.find_by transaction_id: 't-2'
    end
    
    it 'should filter by comment' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.comment = 'This is t-1 comment'
      t1.save!
      
      t2 = described_class.find_by transaction_id: 't-2'
      t2.comment = 'This is t-2 comment'
      t2.save!
      
      result = described_class.search user, account.aggregate_id, criteria: {comment: 'is t-1'}
      expect(result.length).to eql 1
      expect(result[0]).to eql t1
      
      result = described_class.search user, account.aggregate_id, criteria: {comment: 'This is'}
      expect(result.length).to eql 2
      expect(result[0]).to eql t1
      expect(result[1]).to eql t2
    end
  end
  
  def expect_required_attributes transaction
    expect(transaction.attributes.keys).to eql ["id", "transaction_id",
      "account_id", "type_id", "ammount", "tag_ids",
      "comment", "date", "is_transfer", "sending_account_id",
      "sending_transaction_id", "receiving_account_id", "receiving_transaction_id"]
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
      subject.changed_attributes.clear
      subject.add_tag 130
      expect(subject.tag_ids_changed?).to be_truthy
    end
    
    it "should not add the tag_id if already present" do
      subject.changed_attributes.clear
      subject.add_tag 100
      expect(subject.tag_ids).to eql('{100},{110},{120}')
      expect(subject.tag_ids_changed?).to be_falsey
    end
  end
  
  describe "remove_tag" do
    subject { p::Transaction.new }
    before(:each) do
      subject.tag_ids = "{100},{200},{300},{400},{500}"
      subject.changed_attributes.clear
      subject.remove_tag 100
    end
    
    it "should remove the tag" do
      expect(subject.tag_ids).to eql '{200},{300},{400},{500}'
      subject.remove_tag 500
      expect(subject.tag_ids).to eql '{200},{300},{400}'
      subject.remove_tag 300
      expect(subject.tag_ids).to eql '{200},{400}'
    end
    
    it "should mark the tag_ids as changed" do
      expect(subject.tag_ids_changed?).to be_truthy
    end
    
    it "should do nothing if no such tag" do
      subject.tag_ids = "{100}"
      subject.changed_attributes.clear
      subject.remove_tag 300
      expect(subject.tag_ids).to eql '{100}'
      expect(subject.tag_ids_changed?).to be_falsy
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
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', expence_id, 2000, date, [100, 200], 'Comment 1'
    end
    
    it "should update ammount on TransactionAmmountAdjusted" do
      subject.handle_message e::TransactionAmmountAdjusted.new 'account-1', 't-1', 1900
      expect(t1.ammount).to eql 1900
    end
    
    it "should update comment on TransactionCommentAdjusted" do
      subject.handle_message e::TransactionCommentAdjusted.new 'account-1', 't-1', 'New comment 1'
      expect(t1.comment).to eql 'New comment 1'
    end
    
    it "should update date on TransactionDateAdjusted" do
      updated_date = date - 110
      subject.handle_message e::TransactionDateAdjusted.new 'account-1', 't-1', updated_date
      expect(t1.date.to_datetime).to eql updated_date.utc
    end
    
    it "should add new tag on TransactionTagged" do
      subject.handle_message e::TransactionTagged.new 'account-1', 't-1', 110
      expect(t1.tag_ids).to eql '{100},{200},{110}'
    end
    
    it "should add new tag on TransactionUntagged" do
      subject.handle_message e::TransactionUntagged.new 'account-1', 't-1', 100
      expect(t1.tag_ids).to eql '{200}'
      subject.handle_message e::TransactionUntagged.new 'account-1', 't-1', 200
      t1.reload
      expect(t1.tag_ids).to eql ''
    end   
     
    it "should remove on TransactionRemoved" do
      subject.handle_message e::TransactionRemoved.new 'account-1', 't-1'
      expect(t1).to be_nil
    end
  end
  
  describe "on AccountRemoved" do
    let(:account1) { create_account_projection! 'account-1', authorized_user_ids: '{100}' }
    let(:account2) { create_account_projection! 'account-2', authorized_user_ids: '{100}' }
    
    before(:each) do
      date = DateTime.new
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-1', expence_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-2', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-3', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-4', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-5', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-6', expence_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::AccountRemoved.new account1.aggregate_id
    end
    
    it "should remove all belonging transactions" do
      expect(p::Transaction.where(account_id: account1.aggregate_id).length).to eql 0
    end
    
    it "should not affect other transactions" do
      expect(p::Transaction.where(account_id: account2.aggregate_id).length).to eql 3
    end
  end
end
