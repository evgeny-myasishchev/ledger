require 'rails_helper'

describe Domain::Account do
  using AccountHelpers::D
  module I
    include Domain::Events
  end
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expence_id) { Domain::Transaction::ExpenceTypeId }
  let(:refund_id) { Domain::Transaction::RefundTypeId }
  
  describe "create" do
    it "should raise AccountCreated event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('account-100')
      currency = Currency['UAH']
      subject.create 'ledger-100', 1, 'Account 100', currency
      expect(subject).to have_one_uncommitted_event I::AccountCreated, 
        aggregate_id: subject.aggregate_id,
        ledger_id: 'ledger-100', 
        sequential_number: 1,
        name: 'Account 100', 
        currency_code: currency.code
    end
    
    it "should assign the aggregate_id on created event" do
      subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 1, 'Account 332', 'UAH'
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
    it "should raise TransactionReported and AccountBalanceChanged events" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-100')
      date = DateTime.now
      subject.make_created
      subject.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 1060
      subject.report_income '10.40', date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported,
      {
        aggregate_id: subject.aggregate_id,
        transaction_id: 'transaction-100',
        type_id: income_id,
        ammount: 1040,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'
      }, at_index: 0
      
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged,
      {
        aggregate_id: subject.aggregate_id,
        transaction_id: 'transaction-100',
        balance: 2100
      }, at_index: 1
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_income '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_income '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end
  end
    
  describe "report_expence" do
    it "should raise TransactionReported event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-100')
      date = DateTime.now
      subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073
      subject.report_expence '20.23', date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::ExpenceTypeId,
        ammount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        balance: 3050}, at_index: 1
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_expence '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_expence '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end
  end

  describe "report_refund" do
    it "should raise TransactionReported event" do
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-100')
      date = DateTime.now
      subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073
      subject.report_refund '20.23', date, ['t-1', 't-2'], 'Coworker gave back'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::RefundTypeId,
        ammount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Coworker gave back'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        balance: 7096}, at_index: 1
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_refund '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_refund '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end
  end

  describe "send_transfer" do
    before(:each) { subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073 }
    before(:each) { allow(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-110') }

    it "should raise TransferSent and AccountBalanceChanged events" do      
      expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-110')
      date = DateTime.now
      subject.send_transfer 'receiver-account-332', '20.23', date, ['t-1', 't-2'], 'Getting cache'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransferSent, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        receiving_account_id: 'receiver-account-332',
        ammount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        balance: 3050}, at_index: 1
    end

    it "should return transaction_id" do
      expect(subject.send_transfer('receiver-account-332', '20.23', DateTime.now, ['t-1', 't-2'], 'Getting cache')).to eql 'transaction-110'
    end

    it "should accept tags as a single arg" do
      subject.send_transfer('receiver-account-332', '20.23', DateTime.now, 't-1')
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    it "should treat null tags as empty" do
      subject.send_transfer('receiver-account-332', '20.23', DateTime.now, nil)
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end
  end

  describe "receive_transfer" do
    before(:each) { subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073 }
    before(:each) { expect(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-110') }
    let(:date) { DateTime.now }
    it "should raise TransferReceived and AccountBalanceChanged events" do
      
      subject.receive_transfer 'sending-account-332', 'sending-transaction-221', '20.23', date, ['t-1', 't-2'], 'Getting cache'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransferReceived, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        sending_account_id: 'sending-account-332',
        sending_transaction_id: 'sending-transaction-221',
        ammount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        balance: 7096}, at_index: 1
    end

    it "should accept tags as a single arg" do
      subject.receive_transfer 'sending-account-332', 'sending-transaction-221', '20.23', date, ['t-1']
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end

    it "should treat null tags as empty" do
      subject.receive_transfer 'sending-account-332', 'sending-transaction-221', '20.23', date, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end
  end
  
  describe "transaction adjustments" do
    before(:each) do
      subject.make_created
    end
    
    describe "adjust_ammount" do
      before(:each) do
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 11000, DateTime.new, [], ''
        subject.apply_event I::TransactionAmmountAdjusted.new subject.aggregate_id, 't-1', 10000
        
        subject.apply_event I::TransferReceived.new subject.aggregate_id, 't-2', 's-a-1', 's-t-1', 12000, DateTime.new, [], ''
        subject.apply_event I::TransactionAmmountAdjusted.new subject.aggregate_id, 't-2', 10000
        
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-3', expence_id, 10000, DateTime.new, [], ''
        
        subject.apply_event I::TransferSent.new subject.aggregate_id, 't-4', 'r-a-1', 13000, DateTime.new, [], ''
        subject.apply_event I::TransactionAmmountAdjusted.new subject.aggregate_id, 't-4', 10000
        
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-5', refund_id, 10000, DateTime.new, [], ''
        subject.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 't-5', 50000
      end
      
      describe "income transactions" do
        it "should raise balance change and ammount adjustments related events for regular income transaction" do
          subject.adjust_ammount 't-1', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-1', ammount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-1', balance: 45000}, at_index: 1
        end
        
        it "should raise balance change and ammount adjustments related events for transfer transaction" do
          subject.adjust_ammount 't-2', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-2', ammount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-2', balance: 45000}, at_index: 1
        end
        
        it "should raise balance change and ammount adjustments related events for refund transaction" do
          subject.adjust_ammount 't-5', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-5', ammount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-5', balance: 45000}, at_index: 1
        end
      end
      
      describe "expence transactions" do
        it "should raise balance cahnge and ammount adjustments related events for regular expence transaction" do
          subject.adjust_ammount 't-3', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-3', ammount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-3', balance: 55000}, at_index: 1
        end
        
        it "should raise balance cahnge and ammount adjustments related events for transfer transaction" do
          subject.adjust_ammount 't-4', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-4', ammount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-4', balance: 55000}, at_index: 1
        end
      end
    end
  
    describe "adjust_comment" do
      it "should raise TransactionCommentAdjusted" do
        subject.adjust_comment 't-1', 'New comment for t1'
        expect(subject).to have_one_uncommitted_event I::TransactionCommentAdjusted, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-1', comment: 'New comment for t1'
        }
      end
    end
    
    describe "adjust_date" do
      it "should raise TransactionDateAdjusted" do
        date = DateTime.now
        subject.adjust_date 't-1', date
        expect(subject).to have_one_uncommitted_event I::TransactionDateAdjusted, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-1', date: date
        }
      end
    end
  
    describe "adjust_tags" do
      before(:each) do
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 
          't-1', 
          Domain::Transaction::ExpenceTypeId, 
          100, 
          DateTime.new,
          [100, 400, 500],
          'Transaction t-1'
        subject.apply_event I::TransactionUntagged.new subject.aggregate_id, 't-1', 400
        subject.apply_event I::TransactionUntagged.new subject.aggregate_id, 't-1', 500
        subject.adjust_tags 't-1', [100, 200, 300]
        
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 
          't-2', 
          Domain::Transaction::ExpenceTypeId, 
          100, 
          DateTime.new,
          [100],
          'Transaction t-2'
        subject.apply_event I::TransactionTagged.new subject.aggregate_id, 't-2', 200
        subject.apply_event I::TransactionTagged.new subject.aggregate_id, 't-2', 300
        subject.adjust_tags 't-2', [200]
      end
      
      it "it should raise TransactionTagged for each new tag" do
        expect(subject).to have_one_uncommitted_event I::TransactionTagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-1', tag_id: 200
        }, at_index: 0
        expect(subject).to have_one_uncommitted_event I::TransactionTagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-1', tag_id: 300
        }, at_index: 1
      end
      
      it "it should raise TransactionUntagged for each removed tag" do
        expect(subject).to have_one_uncommitted_event I::TransactionUntagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-2', tag_id: 100
        }, at_index: 2
        expect(subject).to have_one_uncommitted_event I::TransactionUntagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-2', tag_id: 300
        }, at_index: 3
      end
      
      it "should treat nil tags as empty" do
        subject.clear_uncommitted_events
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 
          't-3', 
          Domain::Transaction::ExpenceTypeId, 
          100, 
          DateTime.new,
          [100, 200],
          'Transaction t-3'
        subject.adjust_tags 't-3', nil
        expect(subject).to have_one_uncommitted_event I::TransactionUntagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-3', tag_id: 100
        }, at_index: 0
        expect(subject).to have_one_uncommitted_event I::TransactionUntagged, {
          aggregate_id: subject.aggregate_id, transaction_id: 't-3', tag_id: 200
        }, at_index: 1
      end
    end
  end
  
  describe "remove_transaction" do
    before(:each) do
      subject.make_created
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 10000, DateTime.new, [], ''
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-2', refund_id, 10000, DateTime.new, [], ''
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-3', expence_id, 10000, DateTime.new, [], ''
      subject.apply_event I::TransferSent.new subject.aggregate_id, 't-4', 'r-a-1', 10000, DateTime.new, [], ''
      subject.apply_event I::TransferReceived.new subject.aggregate_id, 't-5', 's-a-1', 's-t-1', 10000, DateTime.new, [], ''
      subject.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 't-5', 50000
    end
    
    it "should raise removed and balance change events for income transactions" do
      subject.remove_transaction 't-1'
      expect(subject).to have_one_uncommitted_event I::TransactionRemoved, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-1'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-1', balance: 40000}, at_index: 1
    end
    
    it "should raise removed and balance change events for refund transactions" do
      subject.remove_transaction 't-2'
      expect(subject).to have_one_uncommitted_event I::TransactionRemoved, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-2'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-2', balance: 40000}, at_index: 1
    end
    
    it "should raise removed and balance change for expence transactions" do
      subject.remove_transaction 't-3'
      expect(subject).to have_one_uncommitted_event I::TransactionRemoved, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-3'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-3', balance: 60000}, at_index: 1
    end
        
    it "should raise removed and balance change for transfer sent transactions" do
      subject.remove_transaction 't-4'
      expect(subject).to have_one_uncommitted_event I::TransactionRemoved, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-4'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-4', balance: 60000}, at_index: 1
    end
    
    it "should raise removed and balance change for transfer received transactions" do
      subject.remove_transaction 't-5'
      expect(subject).to have_one_uncommitted_event I::TransactionRemoved, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-5'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, transaction_id: 't-5', balance: 40000}, at_index: 1
    end
    
    it "should do nothing if already removed" do
      subject.apply_event I::TransactionRemoved.new subject.aggregate_id, 't-1'
      subject.remove_transaction 't-1'
      expect(subject).not_to have_uncommitted_events
    end
  end
end