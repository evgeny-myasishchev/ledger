require 'spec_helper'

describe Domain::Account do
  using AccountHelpers
  module I
    include Domain::Events
  end
  
  describe "create" do
    it "should raise AccountCreated event" do
      CommonDomain::Infrastructure::AggregateId.should_receive(:new_id).and_return('account-100')
      currency = Currency['UAH']
      subject.create 'ledger-100', 'Account 100', currency
      subject.should have_one_uncommitted_event I::AccountCreated, ledger_id: 'ledger-100', name: 'Account 100', currency_code: currency.code
    end
    
    it "should assign the aggregate_id on created event" do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 'Account 332', 'UAH'
      subject.aggregate_id.should eql 'account-332'
    end
  end
  
  describe "rename" do
    it "should raise AccountRenamed event" do
      subject.make_created.rename 'Account 332 renamed'
      subject.should have_one_uncommitted_event I::AccountRenamed, name: 'Account 332 renamed'
    end
  end
  
  describe "close" do
    before(:each) do
      subject.make_created
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
    it "should raise TransactionReported event" do
      subject.make_created.report_income '10.40', ['t-1', 't-2'], 'Monthly income'
      subject.should have_one_uncommitted_event I::TransactionReported, type_id: Domain::Transaction::IncomeTypeId, ammount: Money.parse('10.40', Currency['UAH'])
    end
  end
    
  describe "report_expence" do
    it "should raise TransactionReported event" do
      subject.make_created.report_expence '10.40', ['t-1', 't-2'], 'Monthly income'
      subject.should have_one_uncommitted_event I::TransactionReported, type_id: Domain::Transaction::ExpenceTypeId, ammount: Money.parse('10.40', Currency['UAH'])
    end
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