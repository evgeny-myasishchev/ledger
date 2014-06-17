require 'rails_helper'

describe Domain::Account do
  using AccountHelpers
  module I
    include Domain::Events
  end
  
  describe "create" do
    it "should raise AccountCreated event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('account-100')
      currency = Currency['UAH']
      subject.create 'ledger-100', 'Account 100', currency
      expect(subject).to have_one_uncommitted_event I::AccountCreated, 
        aggregate_id: subject.aggregate_id,
        ledger_id: 'ledger-100', 
        name: 'Account 100', 
        currency_code: currency.code
    end
    
    it "should assign the aggregate_id on created event" do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 'Account 332', 'UAH'
      expect(subject.aggregate_id).to eql 'account-332'
    end
  end
  
  describe "rename" do
    it "should raise AccountRenamed event" do
      subject.make_created.rename 'Account 332 renamed'
      expect(subject).to have_one_uncommitted_event I::AccountRenamed, aggregate_id: subject.aggregate_id, name: 'Account 332 renamed'
    end
  end
  
  describe "close" do
    before(:each) do
      subject.make_created
    end
    
    it "should raise AccountClosed event" do
      subject.close
      expect(subject).to have_one_uncommitted_event I::AccountClosed, aggregate_id: subject.aggregate_id
    end
    
    it "should raise nothing if already closed" do
      subject.apply_event I::AccountClosed.new 'account-332'
      expect(subject).not_to have_uncommitted_events
    end
  end
  
  describe "report_income" do
    it "should raise TransactionReported event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-100')
      date = DateTime.now
      subject.make_created.report_income '10.40', date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_one_uncommitted_event I::TransactionReported, 
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::IncomeTypeId,
        ammount: 1040,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'
    end
  end
    
  describe "report_expence" do
    it "should raise TransactionReported event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-100')
      date = DateTime.now
      subject.make_created.report_expence 2023, date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_one_uncommitted_event I::TransactionReported, 
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::ExpenceTypeId,
        ammount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'
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