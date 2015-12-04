require 'rails_helper'


module Projections::PendingTransactionSpec
  include Domain::Events
  
  RSpec.describe Projections::PendingTransaction, :type => :model do
    subject { described_class.create_projection }
    
    def new_reported_event(user_id: 33222, transaction_id: 't-101', amount: '1003.32',
                           date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                           account_id: 'a-100', type_id: Domain::Transaction::ExpenseTypeId)
      PendingTransactionReported.new transaction_id, user_id, amount, date, tag_ids, comment, account_id, type_id
    end
    
    def new_adjusted_event(transaction_id: 't-101', amount: '1003.32',
                           date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                           account_id: 'a-100', type_id: Domain::Transaction::ExpenseTypeId)
      PendingTransactionAdjusted.new transaction_id, amount, date, tag_ids, comment, account_id, type_id
    end
    
    describe 'read methods' do
      let(:user_1) { User.new id: 33222 }
      let(:user_2) { User.new id: 33223 }

      before do
        subject.handle_message new_reported_event user_id: user_1.id, transaction_id: 't-101'
        subject.handle_message new_reported_event user_id: user_1.id, transaction_id: 't-102'
        subject.handle_message new_reported_event user_id: user_1.id, transaction_id: 't-103'
        subject.handle_message new_reported_event user_id: user_2.id, transaction_id: 't-104'
        subject.handle_message new_reported_event user_id: user_2.id, transaction_id: 't-105'
      end
      
      describe 'get_penging_transactions' do
        it 'should return all pending transactions belonging to the given user' do
          user_transactions = described_class.get_pending_transactions user_1
          expect(user_transactions.length).to eql 3
          expect(user_transactions).to include described_class.find_by_transaction_id 't-101'
          expect(user_transactions).to include described_class.find_by_transaction_id 't-102'
          expect(user_transactions).to include described_class.find_by_transaction_id 't-103'
        end
        
        it 'should include allowed attributes only' do
          transaction = described_class.get_pending_transactions(user_1).first
          expect(transaction.attribute_names).to eql %w(id transaction_id amount date tag_ids comment account_id type_id)
        end
      end
        
      describe 'get_penging_transactions_count' do
        it 'should count pending transactions belonging to the given user' do
          expect(described_class.get_pending_transactions_count(user_1)).to eql 3
          expect(described_class.get_pending_transactions_count(user_2)).to eql 2
        end
      end
    end
    
    describe 'on PendingTransactionReported' do
      it 'should insert new pending transaction' do
        event = new_reported_event
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.user_id).to eql event.user_id
        expect(t.amount).to eql event.amount
        expect(t.date.httpdate).to eql event.date.httpdate
        expect(t.tag_ids).to eql '{t-1},{t-2}'
        expect(t.comment).to eql event.comment
        expect(t.account_id).to eql event.account_id
        expect(t.type_id).to eql event.type_id
      end
      
      it 'should handle nil tag_ids' do
        event = new_reported_event tag_ids: nil
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.tag_ids).to be_nil
      end
    
      it 'should handle empty tag_ids' do
        event = new_reported_event tag_ids: ""
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.tag_ids).to be_nil
      end
    
      it 'should be idepmptent' do
        event = new_reported_event
        subject.handle_message event
        expect {
          subject.handle_message event
        }.not_to change { described_class.count }
      end
    end
    
    describe 'on PendingTransactionAdjusted' do
      before do
        described_class.create! transaction_id: 't-101', user_id: 33222, amount: '0', date: DateTime.now.utc, type_id: 0
      end
      
      it 'should update attributes of the pending transaction' do
        event = new_adjusted_event
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.amount).to eql event.amount
        expect(t.date.httpdate).to eql event.date.httpdate
        expect(t.tag_ids).to eql '{t-1},{t-2}'
        expect(t.comment).to eql event.comment
        expect(t.account_id).to eql event.account_id
        expect(t.type_id).to eql event.type_id
      end
      
      it 'should handle nil tag_ids' do
        event = new_adjusted_event tag_ids: nil
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.tag_ids).to be_nil
      end
    end
    
    describe 'on PendingTransactionApproved' do
      before do
        described_class.create! transaction_id: 't-101', user_id: 33222, amount: '0', date: DateTime.now, type_id: 0
      end
      
      it 'should remove the pending transaction' do
        subject.handle_message PendingTransactionApproved.new 't-101'
        expect(described_class.find_by_transaction_id('t-101')).to be_nil
      end
      
      it 'should be idempotent' do
        subject.handle_message PendingTransactionApproved.new 't-101'
        expect { subject.handle_message PendingTransactionApproved.new 't-101' }.not_to change { described_class.count }
      end
    end
    
    describe 'on PendingTransactionRejected' do
      before do
        described_class.create! transaction_id: 't-101', user_id: 33222, amount: '0', date: DateTime.now, type_id: 0
      end
      
      it 'should remove the pending transaction' do
        subject.handle_message PendingTransactionRejected.new 't-101'
        expect(described_class.find_by_transaction_id('t-101')).to be_nil
      end
      
      it 'should be idempotent' do
        subject.handle_message PendingTransactionRejected.new 't-101'
        expect { subject.handle_message PendingTransactionRejected.new 't-101' }.not_to change { described_class.count }
      end
    end
  end
end