require 'spec_helper'

describe Domain::Ledger do
  module I
    include Domain::Events
  end
  
  it "should be an aggregate" do
    subject.should be_an_aggregate
  end
  
  describe "create" do
    it "should raise LedgerCreated event" do
      CommonDomain::Infrastructure::AggregateId.should_receive(:new_id).and_return('ledger-1')
      subject.create 100, 'Ledger 1'
      subject.should have_one_uncommitted_event I::LedgerCreated, user_id: 100, name: 'Ledger 1'
    end
    
    it "should return self" do
      subject.create(100, 'Ledger 1').should be subject
    end
    
    it "should assign the id on LedgerCreated" do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
      subject.aggregate_id.should eql 'ledger-1'
    end
  end
  
  describe "rename" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
    end
    
    it "should raise LedgerRenamed event" do
      subject.rename 'New Ledger 20'
      subject.should have_one_uncommitted_event I::LedgerRenamed, name: 'New Ledger 20'
    end
  end
  
  describe "share" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
    end
    
    it "should share LedgerShared event" do
      subject.share 200
      subject.should have_one_uncommitted_event I::LedgerShared, user_id: 200
    end
        
    it "should not share if already shared" do
      subject.apply_event I::LedgerShared.new 'ledger-1', 200
      subject.share 200
      subject.should_not have_uncommitted_events
    end
  end
  
  describe "create_new_account" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
    end
    
    it "should create new account and return it raising AccountAddedToLedger event" do
      account = double(:account, aggregate_id: 'account-100')
      Domain::Account.should_receive(:new).and_return account
      currency = Currency['UAH']
      account.should_receive(:create).with('ledger-1', 'Account 100', currency)
      subject.create_new_account('Account 100', currency).should be account
      subject.should have_one_uncommitted_event I::AccountAddedToLedger, account_id: 'account-100'
    end
  end
  
  describe "close_account" do
    let(:account) { double(:account, aggregate_id: 'account-100') }
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
    end
    
    it "should raise error if account is from different ledger" do
      different_account = double(:account, aggregate_id: 'account-110')
      lambda { subject.close_account(different_account) }.should raise_error("Account 'account-110' is not from ledger 'Ledger 1'.")
    end
    
    it "should do nothing if already closed" do
      subject.apply_event I::LedgerAccountClosed.new 'ledger-1', 'account-100'
      subject.close_account account
      subject.should_not have_uncommitted_events
      account.should_not_receive(:close)
    end
    
    it "should close the account and raise LedgerAccountClosed event" do
      account.should_receive(:close)
      subject.close_account account
      subject.should have_one_uncommitted_event I::LedgerAccountClosed, account_id: 'account-100'
    end
  end
  
  describe "create_tag" do
    it "should raise TagCreatedEvent"
  end
  
  describe "rename_tag" do
    it "should raise TagRenamedEvent"
  end
  
  describe "remove_tag" do
    it "should raise TagRemovedEvent"
  end
end