require 'rails_helper'

RSpec.describe Projections::Account, :type => :model do
  include AccountHelpers::P
  let(:p) { Projections }
  let(:ledger) {
    p::Ledger.create!(aggregate_id: 'ledger-1', owner_user_id: 22331, shared_with_user_ids: Set.new([22332, 22333]), name: 'ledger 1')
  }
  
  describe "authorize_user" do
    it "should add user id to a list of ids" do
      a = create_account_projection! 'a-2233', ledger.aggregate_id, authorized_user_ids: '{22},{33}'
      a.authorize_user 44
      a.authorize_user 45
      expect(a.authorized_user_ids).to eql "{22},{33},{44},{45}"
      expect(a.authorized_user_ids_changed?).to be_truthy
      
      a = create_account_projection! 'a-1', ledger.aggregate_id, authorized_user_ids: ''
      a.authorize_user 10
      expect(a.authorized_user_ids).to eql "{10}"
    end
  end
  
  describe "ensure_authorized!" do
    subject { create_account_projection! 'a-100', authorized_user_ids: '{22},{23},{213}' }
    
    it "should do nothing if the user is authorized on the account" do
      subject.ensure_authorized! User.new id: 23
    end
    
    it "should raise AuthorizationFailedError if the user is not authorized" do
      expect {
        subject.ensure_authorized! User.new id: 13
      }.to raise_error Errors::AuthorizationFailedError
    end
    
    it "should find and delegate to instance if calling on class" do
      user = User.new id: 123
      expect(described_class).to receive(:find).with(334411) { subject }
      expect(subject).to receive(:ensure_authorized!).with(user) { subject }
      expect(described_class.ensure_authorized!(334411, user)).to be subject
    end
    
    it "should return self" do
      expect(subject.ensure_authorized!(User.new(id: 23))).to be subject
    end
  end
  
  describe "get_user_accounts" do
    it "should return authorized accounts for specified user" do
      user = User.new
      user.id = 100
      
      a1 = create_account_projection! 'a1', 'l1', authorized_user_ids: '{100},{110}'
      a2 = create_account_projection! 'a2', 'l1', authorized_user_ids: '{110},{100},{130}'
      a3 = create_account_projection! 'a3', 'l1', authorized_user_ids: '{110},{130},{100}'
      a4 = create_account_projection! 'a4', 'l1', authorized_user_ids: '{110},{120},{130}'
      
      user_accounts = p::Account.get_user_accounts user
      expect(user_accounts.length).to eql 3
      expect(user_accounts).to include(a1)
      expect(user_accounts).to include(a2)
      expect(user_accounts).to include(a3)
    end
    
    it "should skip system fields that can lead to information flow"
  end
  
  describe "projection" do
    subject { described_class.create_projection }
    let(:e) { Domain::Events }
  
    before(:each) do
      subject.handle_message e::AccountCreated.new 'account-223', ledger.aggregate_id, 1, 'Account 223', 'UAH'
    end
    let(:account_223) { described_class.find_by_aggregate_id 'account-223' }
    
    describe "on AccountCreated" do
      it "should create corresponding record" do
        expect(account_223).not_to be_nil
        expect(account_223.ledger_id).to eql ledger.aggregate_id
        expect(account_223.owner_user_id).to eql ledger.owner_user_id
        expect(account_223.authorized_user_ids).to eql "{22332},{22333},{22331}"
        expect(account_223.currency_code).to eql 'UAH'
        expect(account_223.name).to eql 'Account 223'
        expect(account_223.balance).to eql 0
        expect(account_223.is_closed).to be_falsey
      end
    
      it "should be idempotent" do
        expect { subject.handle_message e::AccountCreated.new 'account-223', 'ledger-1', 1, 'Account 223', 'UAH' }.not_to change { described_class.count }
      end
    end
    
    describe "on LedgerShared" do
      it "should add user id to a list of users for all accounts" do
        a1 = create_account_projection! 'a-1', ledger.aggregate_id
        a2 = create_account_projection! 'a-2', ledger.aggregate_id
        subject.handle_message e::LedgerShared.new ledger.aggregate_id, 110
        subject.handle_message e::LedgerShared.new ledger.aggregate_id, 120
        a1.reload
        a2.reload
        expect(a1.authorized_user_ids).to eql "{100},{110},{120}"
        expect(a2.authorized_user_ids).to eql "{100},{110},{120}"
      end
    end
    
    describe "on AccountRenamed" do
      it "should update the name" do
        subject.handle_message e::AccountRenamed.new 'account-223', 'New Name 223'
        expect(account_223.name).to eql 'New Name 223'
      end
    end
  
    describe "on AccountClosed" do
      it "should mark the account as closed" do
        subject.handle_message e::AccountClosed.new 'account-223'
        expect(account_223.is_closed).to be_truthy
      end
    end
    
    describe "on AccountBalanceChanged" do
      it "should update corresponding balance" do
        a1 = create_account_projection! 'a-1', ledger.aggregate_id
        a2 = create_account_projection! 'a-2', ledger.aggregate_id

        subject.handle_message e::AccountBalanceChanged.new 'a-1', 't-1', 110011
        subject.handle_message e::AccountBalanceChanged.new 'a-2', 't-1', 220022
        
        a1.reload
        a2.reload
        
        expect(a1.balance).to eql 110011
        expect(a2.balance).to eql 220022
      end
    end
  end
end
