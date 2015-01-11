require 'spec_helper'


module PendingTransactionSpec
  include Domain
  include Domain::Events

  describe Domain::PendingTransaction do
    def make_reported subject, user, transaction_id: 't-101', amount: '1003.32', 
        date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101', 
        account_id: 'a-100', type_id: Domain::Transaction::ExpenceTypeId
      subject.apply_event PendingTransactionReported.new transaction_id, user.id, amount, date, tag_ids, comment, account_id, type_id
    end
    
    let(:date) { DateTime.now }
    let(:user) { User.new id: 134911 }
    
    describe 'report' do
      it 'should raise reported event' do
        subject.report user, 't-101', '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101', account_id: 'a-100', type_id: Domain::Transaction::IncomeTypeId
        expect(subject).to have_one_uncommitted_event PendingTransactionReported, 
          aggregate_id: 't-101', 
          user_id: user.id, 
          amount: '1003.32',
          date: date,
          tag_ids: ['t-1', 't-2'],
          comment: 'Transaction 101',
          account_id: 'a-100',
          type_id: Domain::Transaction::IncomeTypeId
      end
    
      it 'should assign attributes on reported' do
        make_reported subject, user, transaction_id: 't-101', amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101', account_id: 'a-100', type_id: Domain::Transaction::IncomeTypeId
        expect(subject.aggregate_id).to eql 't-101'
        expect(subject.user_id).to eql user.id
        expect(subject.amount).to eql '1003.32'
        expect(subject.date).to eql date
        expect(subject.tag_ids).to eql ['t-1', 't-2']
        expect(subject.comment).to eql 'Transaction 101'
        expect(subject.account_id).to eql 'a-100'
        expect(subject.type_id).to eql Domain::Transaction::IncomeTypeId
      end
    end
    
    describe 'adjust' do
      let(:adjusted_date) { date - 100 }
      
      before do
        make_reported subject, user, date: date
      end
      
      it 'should raise adjusted event with changed attributes' do
        subject.adjust amount: '10.05', date: adjusted_date, tag_ids: ['t-21', 't-22'], comment: 'Expence 10.05', account_id: 'a-200', type_id: Domain::Transaction::ExpenceTypeId
        expect(subject).to have_one_uncommitted_event PendingTransactionAdjusted, 
          aggregate_id: 't-101', 
          amount: '10.05',
          date: adjusted_date,
          tag_ids: ['t-21', 't-22'],
          comment: 'Expence 10.05',
          account_id: 'a-200',
          type_id: Domain::Transaction::ExpenceTypeId
      end
      
      it 'should not raise if attributes has not changed' do
        subject.adjust amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101', account_id: 'a-100', type_id: Domain::Transaction::ExpenceTypeId
        expect(subject).not_to have_uncommitted_events
      end
      
      it 'should use existing values if attributes are null' do
        subject.adjust type_id: Domain::Transaction::RefundTypeId
        expect(subject).to have_one_uncommitted_event PendingTransactionAdjusted, 
          aggregate_id: subject.aggregate_id,
          amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101', 
          account_id: 'a-100', type_id: Domain::Transaction::RefundTypeId
      end
      
      it 'should update attributes on reported' do
        subject.apply_event PendingTransactionAdjusted.new 't-101', '10.05', adjusted_date, ['t-21', 't-22'], 'Expence 10.05', 'a-200', Domain::Transaction::ExpenceTypeId
        expect(subject.amount).to eql '10.05'
        expect(subject.date).to eql adjusted_date
        expect(subject.tag_ids).to eql ['t-21', 't-22']
        expect(subject.comment).to eql 'Expence 10.05'
        expect(subject.account_id).to eql 'a-200'
        expect(subject.type_id).to eql Domain::Transaction::ExpenceTypeId
      end
    end
  end
end