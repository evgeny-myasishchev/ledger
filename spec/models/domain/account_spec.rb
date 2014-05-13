require 'spec_helper'

describe Domain::Account do
  module I
    include Domain::Events
  end
  
  describe "create" do
    it "should raise AccountCreated event" do
      CommonDomain::Infrastructure::AggregateId.should_receive(:new_id).and_return('account-100')
      currency = Currency.new id: 3232
      subject.create 'ledger-100', 'Account 100', currency
      subject.should have_one_uncommitted_event I::AccountCreated, ledger_id: 'ledger-100', name: 'Account 100', currency_id: 3232
    end
    
    it "should assign the aggregate_id on created event" do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 'Account 332', 332
      subject.aggregate_id.should eql 'account-332'
    end
  end
  
  describe "rename" do
    it "should raise AccountRenamed event" do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 'Account 332', 332
      subject.rename 'Account 332 renamed'
      subject.should have_one_uncommitted_event I::AccountRenamed, name: 'Account 332 renamed'
    end
  end
  
  describe "close" do
    before(:each) do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 'Account 332', 332
    end
    
    it "should raise AccountClosed event" do
      subject.close
      subject.should have_one_uncommitted_event I::AccountClosed, {}
    end
    
    it "should raise nothing if already closed" do
      subject.apply_event I::AccountClosed.new 'account-332'
    end
  end
  
  describe "report_income" do
    it "should raise TransactionReported event"
  end
    
  describe "report_expence" do
    it "should raise TransactionReported event"
  end
  
  describe "adjust_ammount" do
    it "should raise TransactionAmmountAdjusted"
  end
  
  describe "adjust_comment" do
    it "should raise TransactionCommentAdjusted"
  end
  
  describe "add_tag" do
    it "should raise TransactionTagAdded"
  end
  
  describe "remove_tag" do
    it "should raise TransactionTagRemoved"
  end
end