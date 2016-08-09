require 'rails_helper'

module Projections::PendingTransactionSpec
  include Domain::Events

  RSpec.describe Projections::PendingTransaction, type: :model do
    subject { described_class.create_projection }

    let(:account) { create(:projections_account) }

    def new_reported_event(user_id: 33_222, transaction_id: 't-101', amount: '1003.32',
                           date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                           account_id: account.aggregate_id, type_id: Domain::Transaction::ExpenseTypeId)
      PendingTransactionReported.new transaction_id, user_id, amount, date, tag_ids, comment, account_id, type_id
    end

    def new_adjusted_event(transaction_id: 't-101', amount: '1003.32',
                           date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                           account_id: account.aggregate_id, type_id: Domain::Transaction::ExpenseTypeId)
      PendingTransactionAdjusted.new transaction_id, amount, date, tag_ids, comment, account_id, type_id
    end

    describe 'read methods' do
      let(:user_1) { User.new id: 33_222 }
      let(:user_2) { User.new id: 33_223 }

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

      it 'should handle nil account_id' do
        event = new_reported_event account_id: nil
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.account_id).to be_nil
      end

      it 'should handle empty tag_ids' do
        event = new_reported_event tag_ids: ''
        subject.handle_message event
        t = described_class.find_by_transaction_id 't-101'
        expect(t.tag_ids).to be_nil
      end

      it 'should be idepmptent' do
        event = new_reported_event
        subject.handle_message event
        expect do
          subject.handle_message event
        end.not_to change { described_class.count }
      end

      it 'should notify account projection that pending transaction reported if account present' do
        account = create(:projections_account)
        evt = new_reported_event(account_id: account.aggregate_id, amount: '100.10', type_id: Domain::Transaction::IncomeTypeId)
        expect(Projections::Account).to receive(:find_by).with(aggregate_id: account.aggregate_id) { account }
        expect(account).to receive(:on_pending_transaction_reported).with(evt.amount, evt.type_id)
        expect(account).to receive(:save!)
        subject.handle_message evt
      end
    end

    describe 'on PendingTransactionAdjusted' do
      let(:transaction) { create(:projections_pending_transaction) }

      it 'should update attributes of the pending transaction' do
        event = new_adjusted_event transaction_id: transaction.transaction_id
        subject.handle_message event
        t = described_class.find_by_transaction_id transaction.transaction_id
        expect(t.amount).to eql event.amount
        expect(t.date.httpdate).to eql event.date.httpdate
        expect(t.tag_ids).to eql '{t-1},{t-2}'
        expect(t.comment).to eql event.comment
        expect(t.account_id).to eql event.account_id
        expect(t.type_id).to eql event.type_id
      end

      it 'should handle nil tag_ids' do
        event = new_adjusted_event tag_ids: nil, transaction_id: transaction.transaction_id
        subject.handle_message event
        t = described_class.find_by_transaction_id transaction.transaction_id
        expect(t.tag_ids).to be_nil
      end

      it 'should handle nil account_id' do
        event = new_adjusted_event account_id: nil, transaction_id: transaction.transaction_id
        subject.handle_message event
        t = described_class.find_by_transaction_id transaction.transaction_id
        expect(t.account_id).to be_nil
      end

      it 'should notify account that amount has changed' do
        account = create(:projections_account)
        transaction.update_attributes account_id: account.aggregate_id
        event = new_adjusted_event account_id: account.aggregate_id, transaction_id: transaction.transaction_id, amount: '223.43'

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: account.aggregate_id) { account }
        expect(account).to receive(:on_pending_transaction_adjusted).with(transaction.amount, transaction.type_id, event.amount, event.type_id)
        expect(account).to receive(:save!)

        subject.handle_message event
      end

      it 'should notify old account as well as new if account has changed' do
        old_account = create(:projections_account)
        new_account = create(:projections_account)
        transaction.update_attributes account_id: old_account.aggregate_id
        event = new_adjusted_event account_id: new_account.aggregate_id, transaction_id: transaction.transaction_id,
                                   amount: '223.43', type_id: Domain::Transaction::IncomeTypeId

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: old_account.aggregate_id) { old_account }
        expect(Projections::Account).to receive(:find_by).with(aggregate_id: new_account.aggregate_id) { new_account }

        expect(old_account).to receive(:on_pending_transaction_rejected).with(transaction.amount, transaction.type_id)
        expect(old_account).to receive(:save!)

        expect(new_account).to receive(:on_pending_transaction_reported).with(event.amount, event.type_id)
        expect(new_account).to receive(:save!)

        subject.handle_message event
      end

      it 'should notify just old account if account has been cleared' do
        old_account = create(:projections_account)
        transaction.update_attributes account_id: old_account.aggregate_id
        event = new_adjusted_event account_id: nil, transaction_id: transaction.transaction_id

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: old_account.aggregate_id) { old_account }

        expect(old_account).to receive(:on_pending_transaction_rejected).with(transaction.amount, transaction.type_id)
        expect(old_account).to receive(:save!)

        subject.handle_message event
      end

      it 'should notify just new account if the account has been assigned' do
        new_account = create(:projections_account)
        transaction.update_attributes account_id: nil
        event = new_adjusted_event account_id: new_account.aggregate_id, transaction_id: transaction.transaction_id,
                                   amount: '223.43', type_id: Domain::Transaction::IncomeTypeId

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: new_account.aggregate_id) { new_account }

        expect(new_account).to receive(:on_pending_transaction_reported).with(event.amount, event.type_id)
        expect(new_account).to receive(:save!)

        subject.handle_message event
      end
    end

    describe 'on PendingTransactionApproved' do
      let(:transaction) { create(:projections_pending_transaction) }

      it 'should remove the pending transaction' do
        subject.handle_message PendingTransactionApproved.new transaction.transaction_id
        expect(described_class.find_by_transaction_id(transaction.transaction_id)).to be_nil
      end

      it 'should be idempotent' do
        subject.handle_message PendingTransactionApproved.new transaction.transaction_id
        expect { subject.handle_message PendingTransactionApproved.new transaction.transaction_id }.not_to change { described_class.count }
      end

      it 'should notify account that the transaction has been approved' do
        account = create(:projections_account)
        transaction.update_attributes account_id: account.aggregate_id
        event = PendingTransactionApproved.new transaction.transaction_id

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: account.aggregate_id) { account }

        expect(account).to receive(:on_pending_transaction_approved).with(transaction.amount, transaction.type_id)
        expect(account).to receive(:save!)

        subject.handle_message event
      end
    end

    describe 'on PendingTransactionRejected' do
      let(:transaction) { create(:projections_pending_transaction) }

      it 'should remove the pending transaction' do
        subject.handle_message PendingTransactionRejected.new transaction.transaction_id
        expect(described_class.find_by_transaction_id(transaction.transaction_id)).to be_nil
      end

      it 'should be idempotent' do
        subject.handle_message PendingTransactionRejected.new transaction.transaction_id
        expect { subject.handle_message PendingTransactionRejected.new transaction.transaction_id }.not_to change { described_class.count }
      end

      it 'should notify account that the transaction has been approved' do
        account = create(:projections_account)
        transaction.update_attributes account_id: account.aggregate_id
        event = PendingTransactionRejected.new transaction.transaction_id

        expect(Projections::Account).to receive(:find_by).with(aggregate_id: account.aggregate_id) { account }

        expect(account).to receive(:on_pending_transaction_rejected).with(transaction.amount, transaction.type_id)
        expect(account).to receive(:save!)

        subject.handle_message event
      end
    end
  end
end
