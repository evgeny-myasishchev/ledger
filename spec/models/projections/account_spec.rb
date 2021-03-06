require 'rails_helper'

RSpec.describe Projections::Account, :type => :model do
  include AccountHelpers::P
  let(:p) { Projections }
  let(:ledger) {
    p::Ledger.create!(aggregate_id: 'ledger-1', 
      owner_user_id: 22331, 
      authorized_user_ids: '{22332},{22333},{22331}', 
      name: 'ledger 1',
      currency_code: 'UAH')
  }
  
  describe 'currency' do
    it 'should return appropriate currency' do
      subject.currency_code = 'UAH'
      expect(subject.currency).to eql(Currency['UAH'])
      subject.currency_code = 'EUR'
      expect(subject.currency).to eql(Currency['EUR'])
    end
  end
  
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
      expect(described_class).to receive(:find_by_aggregate_id).with(subject.aggregate_id) { subject }
      expect(subject).to receive(:ensure_authorized!).with(user) { subject }
      expect(described_class.ensure_authorized!(subject.aggregate_id, user)).to be subject
    end
    
    it "should return self" do
      expect(subject.ensure_authorized!(User.new(id: 23))).to be subject
    end
  end

  describe 'on_pending_transaction_reported' do
    let(:account) { create(:projections_account, pending_balance: 10000) }

    it 'should parse the ammount and add it to the pending_balance for income or refund transactions' do
      account.on_pending_transaction_reported '100.25', Domain::Transaction::IncomeTypeId
      account.on_pending_transaction_reported '200.75', Domain::Transaction::RefundTypeId
      expect(account.pending_balance).to eql 40100
    end

    it 'should parse the ammount and subtract it from the pending_balance for expense transactions' do
      account.on_pending_transaction_reported '50.25', Domain::Transaction::ExpenseTypeId
      expect(account.pending_balance).to eql 4975
    end
  end

  describe 'on_pending_transaction_adjusted' do
    let(:account) { create(:projections_account, pending_balance: 40100) }

    it 'should reject old data and report new data' do
      expect(account).to receive(:on_pending_transaction_rejected).with('100.25', Domain::Transaction::IncomeTypeId)
      expect(account).to receive(:on_pending_transaction_reported).with('200.75', Domain::Transaction::RefundTypeId)
      account.on_pending_transaction_adjusted('100.25', Domain::Transaction::IncomeTypeId, '200.75', Domain::Transaction::RefundTypeId)
    end
  end

  describe 'on_pending_transaction_approved' do
    let(:account) { create(:projections_account, pending_balance: 40100) }

    it 'should parse the ammount and subtract it from the pending_balance for income or refund transactions' do
      account.on_pending_transaction_approved '100.25', Domain::Transaction::IncomeTypeId
      account.on_pending_transaction_approved '200.75', Domain::Transaction::RefundTypeId
      expect(account.pending_balance).to eql 10000
    end

    it 'should parse the ammount and add it to the pending_balance for expense transactions' do
      account.on_pending_transaction_approved '50.25', Domain::Transaction::ExpenseTypeId
      expect(account.pending_balance).to eql 45125
    end
  end

  describe 'on_pending_transaction_rejected' do
    let(:account) { create(:projections_account, pending_balance: 40100) }

    it 'should parse the ammount and subtract it from the pending_balance for income or refund transactions' do
      account.on_pending_transaction_rejected '100.25', Domain::Transaction::IncomeTypeId
      account.on_pending_transaction_rejected '200.75', Domain::Transaction::RefundTypeId
      expect(account.pending_balance).to eql 10000
    end

    it 'should parse the ammount and add it to the pending_balance for expense transactions' do
      account.on_pending_transaction_rejected '50.25', Domain::Transaction::ExpenseTypeId
      expect(account.pending_balance).to eql 45125
    end
  end
  
  describe "get_user_accounts" do
    let(:user) { User.new id: 100 }
    before(:each) do
      @a1 = create_account_projection! 'a1', 'l1', authorized_user_ids: '{100},{110}'
      @a2 = create_account_projection! 'a2', 'l1', authorized_user_ids: '{110},{100},{130}'
      @a3 = create_account_projection! 'a3', 'l1', authorized_user_ids: '{110},{130},{100}'
      @a4 = create_account_projection! 'a4', 'l1', authorized_user_ids: '{110},{120},{130}'
      
      @user_accounts = p::Account.get_user_accounts user
    end

    it "should return authorized accounts for specified user" do
      expect(@user_accounts.length).to eql 3
      expect(@user_accounts.detect { |a| a.aggregate_id == 'a1' }).not_to be_nil
      expect(@user_accounts.detect { |a| a.aggregate_id == 'a2' }).not_to be_nil
      expect(@user_accounts.detect { |a| a.aggregate_id == 'a3' }).not_to be_nil
    end
    
    it "should skip system fields that can lead to information flow" do
      actual_a1 = @user_accounts.detect { |a| a.aggregate_id == @a1.aggregate_id }
      expect(actual_a1.attribute_names).to eql(['aggregate_id', 'name', 'balance', 'pending_balance', 'currency_code', 'unit', 'sequential_number', 'category_id', 'is_closed', 'id'])
      expect(actual_a1.id).to be_nil #it's present somehow even if not specified
    end
  end
  
  describe "projection" do
    subject { described_class.create_projection }
    let(:e) { Domain::Events }
  
    before(:each) do
      subject.handle_message e::AccountCreated.new 'account-223', ledger.aggregate_id, 1, 'Account 223', 1000, 'UAH', 'oz'
    end
    let(:account_223) { described_class.find_by_aggregate_id 'account-223' }
    
    describe "on AccountCreated" do
      it "should create corresponding record" do
        expect(account_223).not_to be_nil
        expect(account_223.ledger_id).to eql ledger.aggregate_id
        expect(account_223.owner_user_id).to eql ledger.owner_user_id
        expect(account_223.authorized_user_ids).to eql "{22332},{22333},{22331}"
        expect(account_223.currency_code).to eql 'UAH'
        expect(account_223.unit).to eql 'oz'
        expect(account_223.name).to eql 'Account 223'
        expect(account_223.balance).to eql 1000
        expect(account_223.is_closed).to be_falsey
      end
    
      it "should be idempotent" do
        expect { subject.handle_message e::AccountCreated.new 'account-223', 'ledger-1', 1, 'Account 223', 0, 'UAH', 'oz' }.not_to change { described_class.count }
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
    
    describe "on AccountReopened" do
      it "should clear closed flag" do
        account_223.is_closed = true
        subject.handle_message e::AccountReopened.new 'account-223'
        account_223.reload
        expect(account_223.is_closed).to be_falsy
      end
    end
    
    describe "on AccountRemoved" do
      it "should delete the account" do
        account_223 #to have it loaded
        subject.handle_message e::AccountRemoved.new 'account-223'
        expect(described_class.exists?(account_223.id)).to be_falsy
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
    
    describe "on AccountCategoryAssigned" do
      it "should update category_id" do
        a1 = create_account_projection! 'a-1', ledger.aggregate_id
        a2 = create_account_projection! 'a-2', ledger.aggregate_id

        subject.handle_message e::AccountCategoryAssigned.new ledger.aggregate_id, 'a-1', 110011
        subject.handle_message e::AccountCategoryAssigned.new ledger.aggregate_id, 'a-2', 220022
        
        a1.reload
        a2.reload
        
        expect(a1.category_id).to eql 110011
        expect(a2.category_id).to eql 220022
      end
    end
  end
end
