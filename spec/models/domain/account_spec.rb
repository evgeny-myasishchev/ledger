require 'rails_helper'

describe Domain::Account do
  using AccountHelpers::D
  module I
    include Domain::Events
  end
  let(:i) {
    Module.new do
      include Domain
    end
  }
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expence_id) { Domain::Transaction::ExpenceTypeId }
  let(:refund_id) { Domain::Transaction::RefundTypeId }
  
  describe "create" do
    it "should raise AccountCreated event" do
      currency = Currency['UAH']
      subject.create 'ledger-100', i::Account::AccountId.new('account-100', 1), i::Account::InitialData.new('Account 100', '100.32', currency, 'oz')
      expect(subject).to have_one_uncommitted_event I::AccountCreated, 
        aggregate_id: subject.aggregate_id,
        ledger_id: 'ledger-100', 
        sequential_number: 1,
        name: 'Account 100', 
        initial_balance: 10032,
        currency_code: currency.code,
        unit: 'oz'
    end
    
    it 'should set currency unit if it was not provided with initial data' do
      currency = Currency['XAU']
      subject.create 'ledger-100', i::Account::AccountId.new('account-100', 1), i::Account::InitialData.new('Account 100', '100.32', currency)
      expect(subject).to have_one_uncommitted_event I::AccountCreated, 
        aggregate_id: subject.aggregate_id,
        ledger_id: 'ledger-100', 
        sequential_number: 1,
        name: 'Account 100',
        initial_balance: 10032,
        currency_code: currency.code,
        unit: currency.unit
    end

    describe 'on AccountCreated' do
      before do
        subject.apply_event I::AccountCreated.new 'account-332', 'ledger-100', 432, 'Account 332', 100, 'UAH', 'uz'
      end

      it "should assign the aggregate_id on created event" do        
        expect(subject.aggregate_id).to eql 'account-332'
      end

      it "should assign initial attributes on created event" do
        expect(subject.ledger_id).to eql 'ledger-100'
        expect(subject.sequential_number).to eql 432
        expect(subject.name).to eql 'Account 332'
        expect(subject.balance).to eql 100
        expect(subject.currency).to eql Currency['UAH']
        expect(subject.unit).to eql 'uz'
      end      
    end    
  end
  
  describe "rename" do
    it "should raise AccountRenamed event" do
      subject.make_created.rename 'Account 332 renamed'
      expect(subject).to have_one_uncommitted_event I::AccountRenamed, aggregate_id: subject.aggregate_id, name: 'Account 332 renamed'
    end
    
    it "should not raise any event if name hasn't changed" do
      subject.make_created.rename 'New name 9932'
      subject.clear_uncommitted_events
      subject.rename 'New name 9932'
      expect(subject).not_to have_uncommitted_events
    end

    it 'should update name on AccountRenamed' do
      subject.make_created.apply_event I::AccountRenamed.new subject.aggregate_id, 'Account 332 renamed'
      expect(subject.name).to eql 'Account 332 renamed'
    end
  end
  
  describe "set_unit" do
    it "should raise AccountUnitAdjusted event" do
      subject.make_created.set_unit 'oz'
      expect(subject).to have_one_uncommitted_event I::AccountUnitAdjusted, aggregate_id: subject.aggregate_id, unit: 'oz'
    end
    
    it "should not raise any event if the unit hasn't changed" do
      subject.make_created unit: 'g'
      subject.set_unit 'g'
      expect(subject).not_to have_uncommitted_events
    end

    it 'should set unit attribute' do
      subject.make_created.apply_event I::AccountUnitAdjusted.new subject.aggregate_id, 'oz'
      expect(subject.unit).to eql 'oz'
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

    describe 'on AccountClosed' do
      before do
        subject.apply_event I::AccountClosed.new 'account-332'
      end

      it "should raise nothing if already closed" do        
        subject.apply_event I::AccountClosed.new 'account-332'
        expect(subject).not_to have_uncommitted_events
      end

      it 'should set is_open to false' do
        expect(subject.is_open).to be_falsy
      end      
    end    
  end
  
  describe "reopen" do
    before(:each) do
      subject.make_created
      subject.apply_event I::AccountClosed.new subject.aggregate_id
    end
    
    it "should raise AccountReopened event" do
      subject.reopen
      expect(subject).to have_one_uncommitted_event I::AccountReopened, aggregate_id: subject.aggregate_id
    end
    
    it "should raise error if not closed" do
      subject.apply_event I::AccountReopened.new subject.aggregate_id
      expect { subject.reopen }.to raise_error "Account '#{subject.aggregate_id}' is not closed."
    end

    it 'should set is_open to true on reopen' do
      subject.apply_event I::AccountReopened.new subject.aggregate_id
      expect(subject.is_open).to be_truthy
    end
  end
  
  describe "remove" do
    before(:each) do
      subject.make_created
      subject.apply_event I::AccountClosed.new subject.aggregate_id
    end
    
    it "should raise AccountReopened event" do
      subject.remove
      expect(subject).to have_one_uncommitted_event I::AccountRemoved, aggregate_id: subject.aggregate_id
    end
    
    it "should raise error if not closed" do
      subject.apply_event I::AccountReopened.new subject.aggregate_id
      expect { subject.remove }.to raise_error "Account '#{subject.aggregate_id}' is not closed."
    end
    
    it "should do nothing if already removed" do
      subject.apply_event I::AccountRemoved.new subject.aggregate_id
      subject.remove
      expect(subject).not_to have_uncommitted_events
    end

    it 'should set is_removed flag on AccountRemoved' do
      subject.apply_event I::AccountRemoved.new subject.aggregate_id
      expect(subject.is_removed).to be_truthy
    end
  end

  describe 'on AccountBalanceChanged' do
    it 'should update the balance' do
      subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 1060332
      expect(subject.balance).to eql 1060332
    end
  end
  
  describe "report_income" do
    it "should raise TransactionReported and AccountBalanceChanged events" do
      date = DateTime.now
      subject.make_created
      subject.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 1060
      subject.report_income 'transaction-100', '10.40', date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported,
      {
        aggregate_id: subject.aggregate_id,
        transaction_id: 'transaction-100',
        type_id: income_id,
        amount: 1040,
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
    
    it 'should fail if transaction_id is not unique' do
      subject.make_created.report_income 'transaction-100', '10.00', DateTime.now
      expect { subject.report_income 'transaction-100', '10.00', DateTime.now }.to raise_error ArgumentError, "transaction_id='transaction-100' is not unique."
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_income 'transaction-100', '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_income 'transaction-100', '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end

    it 'should add transaction to transactions on TransactionReported' do
      date = DateTime.now
      subject.make_created.apply_event I::TransactionReported.new(subject.aggregate_id, 
        'transaction-100', income_id, 1040, date, ['t-1', 't-2'], 'Monthly income')
      expect(subject.transactions['transaction-100']).to eql({
        id: 'transaction-100',
        type_id: income_id,
        amount: 1040,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'
      })
    end
  end
    
  describe "report_expense" do
    it "should raise TransactionReported event" do
      date = DateTime.now
      subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073
      subject.report_expense 'transaction-100', '20.23', date, ['t-1', 't-2'], 'Monthly income'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::ExpenceTypeId,
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        balance: 3050}, at_index: 1
    end
    
    it 'should fail if transaction_id is not unique' do
      subject.make_created.report_expense('transaction-100', '20.23', DateTime.now)
      expect { subject.report_expense('transaction-100', '20.23', DateTime.now) }.to raise_error ArgumentError, "transaction_id='transaction-100' is not unique."
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_expense 'transaction-100', '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_expense 'transaction-100', '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end

    it 'should add transaction to transactions on TransactionReported' do
      date = DateTime.now
      subject.make_created.apply_event I::TransactionReported.new(subject.aggregate_id, 
        'transaction-100', Domain::Transaction::ExpenceTypeId, 2023, date, ['t-1', 't-2'], 'Monthly income')
      expect(subject.transactions['transaction-100']).to eql({
        id: 'transaction-100',
        type_id: Domain::Transaction::ExpenceTypeId,
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Monthly income'
      })
    end
  end

  describe "report_refund" do
    it "should raise TransactionReported event" do
      date = DateTime.now
      subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073
      subject.report_refund 'transaction-100', '20.23', date, ['t-1', 't-2'], 'Coworker gave back'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransactionReported, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        type_id: Domain::Transaction::RefundTypeId,
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Coworker gave back'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-100',
        balance: 7096}, at_index: 1
    end
    
    it 'should fail if transaction_id is not unique' do
      subject.make_created.report_refund('transaction-100', '20.23', DateTime.now)
      expect { subject.report_refund('transaction-100', '20.23', DateTime.now) }.to raise_error ArgumentError, "transaction_id='transaction-100' is not unique."
    end
    
    it "should accept tags as a single arg" do
      subject.make_created.report_refund 'transaction-100', '10.00', DateTime.now, 't-1', nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end
    
    it "should treat null tags as empty" do
      subject.make_created.report_refund 'transaction-100', '10.00', DateTime.now, nil, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end

    it 'should add transaction to transactions on TransactionReported' do
      date = DateTime.now
      subject.make_created.apply_event I::TransactionReported.new(subject.aggregate_id, 
        'transaction-100', Domain::Transaction::RefundTypeId, 2023, date, ['t-1', 't-2'], 'Coworker gave back')
      expect(subject.transactions['transaction-100']).to eql({
        id: 'transaction-100',
        type_id: Domain::Transaction::RefundTypeId,
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Coworker gave back'
      })
    end
  end

  describe "send_transfer" do
    before(:each) { subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073 }
    before(:each) { allow(CommonDomain::Infrastructure::AggregateId).to receive(:new_id).and_return('transaction-110') }

    it "should raise TransferSent and AccountBalanceChanged events" do      
      date = DateTime.now
      subject.send_transfer 'transaction-110', 'receiver-account-332', '20.23', date, ['t-1', 't-2'], 'Getting cache'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransferSent, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        receiving_account_id: 'receiver-account-332',
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        balance: 3050}, at_index: 1
    end
    
    it 'should fail if transaction_id is not unique' do
      subject.send_transfer 'transaction-110', 'receiver-account-332', '20.23', DateTime.now
      expect { subject.send_transfer 'transaction-110', 'receiver-account-332', '20.23', DateTime.now }.to raise_error ArgumentError, "transaction_id='transaction-110' is not unique."
    end
    
    it 'should fail if receiving account is the same' do
      expect { subject.send_transfer 'transaction-110', subject.aggregate_id, '20.23', DateTime.now }.to raise_error ArgumentError, "Can not send transfer onto the same account '#{subject.aggregate_id}'."
    end

    it "should return transaction_id" do
      expect(subject.send_transfer('transaction-110', 'receiver-account-332', '20.23', DateTime.now, ['t-1', 't-2'], 'Getting cache')).to eql 'transaction-110'
    end

    it "should accept tags as a single arg" do
      subject.send_transfer('transaction-110', 'receiver-account-332', '20.23', DateTime.now, 't-1')
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end

    it "should treat null tags as empty" do
      subject.send_transfer('transaction-110', 'receiver-account-332', '20.23', DateTime.now, nil)
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end

    it 'should add transaction to transactions on TransferSent' do
      date = DateTime.now
      subject.make_created.apply_event I::TransferSent.new(subject.aggregate_id, 
        'transaction-110', 'receiver-account-332', 2023, date, ['t-1', 't-2'], 'Getting cache')
      expect(subject.transactions['transaction-110']).to eql({
        id: 'transaction-110',
        type_id: Domain::Transaction::ExpenceTypeId,
        is_transfer: true,
        receiving_account_id: 'receiver-account-332',
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'
      })
    end
  end

  describe "receive_transfer" do
    before(:each) { subject.make_created.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 'transaction-100', 5073 }
    let(:date) { DateTime.now }

    it "should raise TransferReceived and AccountBalanceChanged events" do      
      subject.receive_transfer 'transaction-110', 'sending-account-332', 'sending-transaction-221', '20.23', date, ['t-1', 't-2'], 'Getting cache'
      expect(subject).to have_uncommitted_events exactly: 2
      expect(subject).to have_one_uncommitted_event I::TransferReceived, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        sending_account_id: 'sending-account-332',
        sending_transaction_id: 'sending-transaction-221',
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'}, at_index: 0
      expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
        aggregate_id: subject.aggregate_id, 
        transaction_id: 'transaction-110',
        balance: 7096}, at_index: 1
    end
    
    it 'should fail if transaction_id is not unique' do
      subject.receive_transfer 'transaction-110', 'sending-account-332', 'sending-transaction-221', '20.23', DateTime.now
      expect { subject.receive_transfer 'transaction-110', 'sending-account-332', 'sending-transaction-221', '20.23', DateTime.now }.to raise_error ArgumentError, "transaction_id='transaction-110' is not unique."
    end

    it "should accept tags as a single arg" do
      subject.receive_transfer 'transaction-110', 'sending-account-332', 'sending-transaction-221', '20.23', date, ['t-1']
      expect(subject.get_uncommitted_events[0].tag_ids).to eql ['t-1']
    end

    it "should treat null tags as empty" do
      subject.receive_transfer 'transaction-110', 'sending-account-332', 'sending-transaction-221', '20.23', date, nil
      expect(subject.get_uncommitted_events[0].tag_ids).to eql []
    end

    it 'should add transaction to transactions on TransferSent' do
      date = DateTime.now
      subject.make_created.apply_event I::TransferReceived.new(
        subject.aggregate_id, 'transaction-110', 'sending-account-332', 'sending-transaction-221', 2023, date, ['t-1', 't-2'], 'Getting cache')
      expect(subject.transactions['transaction-110']).to eql({
        id: 'transaction-110',
        type_id: Domain::Transaction::IncomeTypeId,
        is_transfer: true,
        sending_account_id: 'sending-account-332',
        sending_transaction_id: 'sending-transaction-221',
        amount: 2023,
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Getting cache'
      })
    end
  end
  
  describe "transaction adjustments" do
    before(:each) do
      subject.make_created
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 11000, DateTime.new, [], ''
    end
    
    describe "adjust_amount" do
      before(:each) do
        subject.apply_event I::TransactionAmountAdjusted.new subject.aggregate_id, 't-1', 10000
        
        subject.apply_event I::TransferReceived.new subject.aggregate_id, 't-2', 's-a-1', 's-t-1', 12000, DateTime.new, [], ''
        subject.apply_event I::TransactionAmountAdjusted.new subject.aggregate_id, 't-2', 10000
        
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-3', expence_id, 10000, DateTime.new, [], ''
        
        subject.apply_event I::TransferSent.new subject.aggregate_id, 't-4', 'r-a-1', 13000, DateTime.new, [], ''
        subject.apply_event I::TransactionAmountAdjusted.new subject.aggregate_id, 't-4', 10000
        
        subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-5', refund_id, 10000, DateTime.new, [], ''
        subject.apply_event I::AccountBalanceChanged.new subject.aggregate_id, 't-5', 50000
      end

      it 'should update transaction ammount on TransactionAmountAdjusted' do
        expect(subject.transactions['t-1'][:amount]).to eql 10000
      end
      
      describe "income transactions" do
        it "should raise balance change and amount adjustments related events for regular income transaction" do
          subject.adjust_amount 't-1', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-1', amount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-1', balance: 45000}, at_index: 1
        end
        
        it "should raise balance change and amount adjustments related events for transfer transaction" do
          subject.adjust_amount 't-2', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-2', amount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-2', balance: 45000}, at_index: 1
        end
        
        it "should raise balance change and amount adjustments related events for refund transaction" do
          subject.adjust_amount 't-5', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-5', amount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-5', balance: 45000}, at_index: 1
        end
        
        it "should raise nothing if the amount didn't change" do
          subject.adjust_amount 't-1', 10000
          subject.adjust_amount 't-2', 10000
          subject.adjust_amount 't-5', 10000
          expect(subject).not_to have_uncommitted_events
        end
      end
      
      describe "expence transactions" do
        it "should raise balance cahnge and amount adjustments related events for regular expence transaction" do
          subject.adjust_amount 't-3', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-3', amount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-3', balance: 55000}, at_index: 1
        end
        
        it "should raise balance cahnge and amount adjustments related events for transfer transaction" do
          subject.adjust_amount 't-4', '50.00'
          expect(subject).to have_one_uncommitted_event I::TransactionAmountAdjusted, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-4', amount: 5000}, at_index: 0
          expect(subject).to have_one_uncommitted_event I::AccountBalanceChanged, {
            aggregate_id: subject.aggregate_id, transaction_id: 't-4', balance: 55000}, at_index: 1
        end
        
        it "should raise nothing if the amount didn't change" do
          subject.adjust_amount 't-3', 10000
          subject.adjust_amount 't-4', 10000
          expect(subject).not_to have_uncommitted_events
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
      
      it "should raise nothing if comment is the same" do
        subject.apply_event I::TransactionCommentAdjusted.new subject.aggregate_id, 't-1', 'Comment t1'
        subject.adjust_comment 't-1', 'Comment t1'
        expect(subject).not_to have_uncommitted_events
      end

      it 'should update transaction comment on TransactionCommentAdjusted' do
        subject.apply_event I::TransactionCommentAdjusted.new subject.aggregate_id, 't-1', 'Comment t1'
        expect(subject.transactions['t-1'][:comment]).to eql 'Comment t1'
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
      
      it "should raise nothing if date is the same" do
        date = DateTime.new
        subject.apply_event I::TransactionDateAdjusted.new subject.aggregate_id, 't-1', date
        subject.adjust_date 't-1', date
        expect(subject).not_to have_uncommitted_events
      end

      it 'should update transaction date on TransactionDateAdjusted' do
        date = DateTime.new
        subject.apply_event I::TransactionDateAdjusted.new subject.aggregate_id, 't-1', date
        expect(subject.transactions['t-1'][:date]).to eql date
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

      it 'should add transaction tag on TransactionTagged/Untagged' do
        expect(subject.transactions['t-1'][:tag_ids]).to eql [100, 200, 300]
        expect(subject.transactions['t-2'][:tag_ids]).to eql [200]
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
      
      it "should raise nothing if tags are the same" do
        subject.clear_uncommitted_events
        subject.adjust_tags 't-1', [100, 200, 300]
        expect(subject).not_to have_uncommitted_events
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

    it 'should remove the transaction on TransactionRemoved' do
      subject.apply_event I::TransactionRemoved.new subject.aggregate_id, 't-1'
      expect(subject.transactions['t-1']).to be_nil
    end
  end
  
  describe 'move_transaction_to' do
    let(:target_account) { described_class.new.make_created }
    before do
      subject.make_created
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 10000, DateTime.new, [], ''
      allow(subject).to receive(:remove_transaction).and_call_original
      allow(target_account).to receive(:accept_moved_transaction_from).and_call_original
      @transaction = subject.transactions['t-1']
      subject.move_transaction_to 't-1', target_account
    end
    
    it 'should raise error if moving to the same account' do
      subject.apply_event I::TransactionReported.new subject.aggregate_id, 't-2', income_id, 10000, DateTime.new, [], ''
      expect { subject.move_transaction_to 't-2', subject }.to raise_error(ArgumentError, "Can not move transaction 't-2' onto the same account.")
    end
    
    it 'should remove the transaction' do
      expect(subject).to have_received(:remove_transaction).with('t-1')
    end
    
    it 'should accept moved transaction by target account' do
      expect(target_account).to have_received(:accept_moved_transaction_from).with(subject, @transaction)
    end
    
    it 'should raise moved event' do
      expect(subject).to have_one_uncommitted_event I::TransactionMovedTo, {
        aggregate_id: subject.aggregate_id, target_account_id: target_account.aggregate_id, transaction_id: 't-1'}, at_index: 2
    end
  end
  
  describe 'accept_moved_transaction_from' do
    let(:sending_account) { described_class.new.make_created }
    let(:date) { DateTime.now }
    
    before do
      subject.make_created
    end
    
    it 'should report income if transaction is income' do
      sending_account.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 10000, DateTime.new, ['tag-1', 'tag-2'], 'Comment t1'
      t = sending_account.transactions['t-1']
      expect(subject).to receive(:report_income).with t[:id], t[:amount], t[:date], t[:tag_ids], t[:comment]
      subject.accept_moved_transaction_from sending_account, t
    end
    
    it 'should report expense if transaction is expense' do
      sending_account.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', expence_id, 10000, DateTime.new, ['tag-1', 'tag-2'], 'Comment t1'
      t = sending_account.transactions['t-1']
      expect(subject).to receive(:report_expense).with t[:id], t[:amount], t[:date], t[:tag_ids], t[:comment]
      subject.accept_moved_transaction_from sending_account, t
    end
    
    it 'should report refund if transaction is refund' do
      sending_account.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', refund_id, 10000, DateTime.new, ['tag-1', 'tag-2'], 'Comment t1'
      t = sending_account.transactions['t-1']
      expect(subject).to receive(:report_refund).with t[:id], t[:amount], t[:date], t[:tag_ids], t[:comment]
      subject.accept_moved_transaction_from sending_account, t
    end
    
    it 'should send transfer if transaction is expense and transfer' do
      sending_account.apply_event I::TransferSent.new(subject.aggregate_id,
        't-1', 'receiver-account-332', 2023, date, ['t-1', 't-2'], 'Comment t-1')
      t = sending_account.transactions['t-1']
      expect(subject).to receive(:send_transfer).with t[:id], t[:receiving_account_id], t[:amount], t[:date], t[:tag_ids], t[:comment]
      subject.accept_moved_transaction_from sending_account, t
    end
    
    it 'should receive transfer if transaction is income and transfer' do
      sending_account.apply_event I::TransferReceived.new(
        subject.aggregate_id, 't-1', 'sending-account-332', 'sending-transaction-221', 2023, date, ['t-1', 't-2'], 'Comment t-1')
      t = sending_account.transactions['t-1']
      expect(subject).to receive(:receive_transfer).with t[:id], t[:sending_account_id], t[:sending_transaction_id], t[:amount], t[:date], t[:tag_ids], t[:comment]
      subject.accept_moved_transaction_from sending_account, t
    end
    
    it 'should raise TransactionMovedFrom event' do
      sending_account.apply_event I::TransactionReported.new subject.aggregate_id, 't-1', income_id, 10000, DateTime.new, ['tag-1', 'tag-2'], 'Comment t1'
      t = sending_account.transactions['t-1']
      subject.accept_moved_transaction_from sending_account, t
      expect(subject).to have_one_uncommitted_event I::TransactionMovedFrom, {
        aggregate_id: subject.aggregate_id, sending_account_id: sending_account.aggregate_id, transaction_id: 't-1'}, at_index: 2
    end
  end
  
  describe 'snapshots' do
    describe 'get_snapshot' do
      it 'should return the entire state of the account' do
        date = DateTime.now
        subject.make_created 'account-1', 'ledger-1', 'Account 1', 100000, 'UAH', unit: 'uz'
        subject.report_income 'transaction-110', 100, date, ['t1', 't2'], 'Transaction 100'
        snapshot = subject.get_snapshot
        expect(snapshot).to include({
          ledger_id: 'ledger-1',
          sequential_number: 1,
          name: 'Account 1',
          currency_code: 'UAH',
          unit: 'uz',
          is_open: true,
          is_removed: false,
          balance: 100100,
          transactions: subject.transactions
        })
      end
    end
    
    describe 'apply_snapshot' do
      it 'should restore the state from the snapshot' do
        date = DateTime.now
        subject.apply_snapshot({
          ledger_id: 'ledger-1',
          sequential_number: 1,
          name: 'Account 1',
          currency_code: 'UAH',
          unit: 'uz',
          is_open: true,
          is_removed: false,
          balance: 100100,
          transactions: {
            't-100' => {
              type_id: income_id,
              amount: 100,
              tag_ids: ['t1', 't2'],
              date: date,
              comment: 'Transaction 100'
            },
            't-101' => {
              type_id: income_id,
              amount: 110,
              tag_ids: ['t3', 't4'],
              date: date,
              comment: 'Transaction 110'
            }
          }
        })
        expect(subject.ledger_id).to eql 'ledger-1'
        expect(subject.sequential_number).to eql 1
        expect(subject.name).to eql 'Account 1'
        expect(subject.currency).to eql Currency['UAH']
        expect(subject.unit).to eql 'uz'
        expect(subject.is_open).to be_truthy
        expect(subject.is_removed).to be_falsy
        expect(subject.balance).to eql 100100
        expect(subject.transactions).to eql({
          't-100' => {
            type_id: income_id,
            amount: 100,
            tag_ids: ['t1', 't2'],
            date: date,
            comment: 'Transaction 100'
          },
          't-101' => {
            type_id: income_id,
            amount: 110,
            tag_ids: ['t3', 't4'],
            date: date,
            comment: 'Transaction 110'
          }
        })
      end
    end
    
    describe 'self.add_snapshot?' do
      it 'should be true if the aggregate has more than 10 applied events' do
        allow(subject).to receive(:applied_events_number) { 10 }
        expect(described_class.add_snapshot?(subject)).to be_falsy
        allow(subject).to receive(:applied_events_number) { 11 }
        expect(described_class.add_snapshot?(subject)).to be_truthy
      end
    end
  end
end
