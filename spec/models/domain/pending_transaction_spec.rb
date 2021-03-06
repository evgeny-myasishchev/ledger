require 'spec_helper'

module PendingTransactionSpec
  include Domain
  include Domain::Events

  describe Domain::PendingTransaction do
    using AccountHelpers::D
    def make_reported(subject, user, transaction_id: 't-101', amount: '1003.32',
                      date: DateTime.now, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                      account_id: 'a-100', type_id: Domain::Transaction::ExpenseTypeId)
      subject.apply_event PendingTransactionReported.new transaction_id, user.id, amount, date, tag_ids, comment, account_id, type_id
    end

    let(:date) { DateTime.now }
    let(:user) { User.new id: 134_911 }

    describe 'report' do
      it 'should fail if transaction_id is empty' do
        expect { subject.report user, nil, '100.4' }.to raise_error ArgumentError, 'transaction_id can not be empty.'
      end

      it 'should fail if amount is empty' do
        expect { subject.report user, 't-101', nil }.to raise_error ArgumentError, 'amount can not be empty.'
      end

      it 'should fail if date is empty' do
        expect { subject.report user, 't-101', '100.4', date: nil }.to raise_error ArgumentError, 'date can not be empty.'
      end

      it 'should apply default type_id if not provided' do
        subject.report user, 't-101', '100.4', date: date
        expect(subject.type_id).to eql Domain::Transaction::ExpenseTypeId
      end

      it 'should apply default type_id if empty provided' do
        subject.report user, 't-101', '100.4', date: date, type_id: ''
        expect(subject.type_id).to eql Domain::Transaction::ExpenseTypeId
      end

      it 'should apply default type_id if nil' do
        subject.report user, 't-101', '100.4', date: date, type_id: nil
        expect(subject.type_id).to eql Domain::Transaction::ExpenseTypeId
      end

      it 'should raise reported event' do
        subject.report user, 't-101', '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                                                 account_id: 'a-100', type_id: Domain::Transaction::IncomeTypeId
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
        make_reported subject, user, transaction_id: 't-101', amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'],
                                     comment: 'Transaction 101', account_id: 'a-100', type_id: Domain::Transaction::IncomeTypeId
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

      it 'should fail if already approved' do
        subject.apply_event PendingTransactionApproved.new subject.aggregate_id
        expect do
          subject.adjust
        end.to raise_error Errors::DomainError, "pending transaction id=(#{subject.aggregate_id}) has already been approved."
      end

      it 'should fail if rejected' do
        subject.apply_event PendingTransactionRejected.new subject.aggregate_id
        expect do
          subject.adjust
        end.to raise_error Errors::DomainError, "pending transaction id=(#{subject.aggregate_id}) has been rejected."
      end

      it 'should raise adjusted event with changed attributes' do
        subject.adjust amount: '10.05', date: adjusted_date, tag_ids: ['t-21', 't-22'], comment: 'Expence 10.05',
                       account_id: 'a-200', type_id: Domain::Transaction::ExpenseTypeId
        expect(subject).to have_one_uncommitted_event PendingTransactionAdjusted,
                                                      aggregate_id: 't-101',
                                                      amount: '10.05',
                                                      date: adjusted_date,
                                                      tag_ids: ['t-21', 't-22'],
                                                      comment: 'Expence 10.05',
                                                      account_id: 'a-200',
                                                      type_id: Domain::Transaction::ExpenseTypeId
      end

      it 'should not raise if attributes has not changed' do
        subject.adjust amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'], comment: 'Transaction 101',
                       account_id: 'a-100', type_id: Domain::Transaction::ExpenseTypeId
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
        subject.apply_event PendingTransactionAdjusted.new 't-101', '10.05', adjusted_date, ['t-21', 't-22'],
                                                           'Expence 10.05', 'a-200', Domain::Transaction::ExpenseTypeId
        expect(subject.amount).to eql '10.05'
        expect(subject.date).to eql adjusted_date
        expect(subject.tag_ids).to eql ['t-21', 't-22']
        expect(subject.comment).to eql 'Expence 10.05'
        expect(subject.account_id).to eql 'a-200'
        expect(subject.type_id).to eql Domain::Transaction::ExpenseTypeId
      end
    end

    describe 'approve' do
      let(:account) { Domain::Account.new.make_created 'account-100' }

      it 'should fail if account_id is empty' do
        subject.report user, 't-100', '10.5'
        expect { subject.approve account }.to raise_error Errors::DomainError, 'account_id is empty.'
      end

      it 'should fail if account is wrong' do
        subject.report user, 't-100', '10.5', account_id: 'account-101'
        expect { subject.approve account }.to raise_error Errors::DomainError,
                                                          "account is wrong. Expected account='account-101' but was account='account-100'."
      end

      it 'should fail if already approved' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        subject.apply_event PendingTransactionApproved.new subject.aggregate_id
        expect { subject.approve account }.to raise_error Errors::DomainError, 'pending transaction id=(t-100) has already been approved.'
      end

      it 'should fail if rejected' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        subject.apply_event PendingTransactionRejected.new subject.aggregate_id
        expect do
          subject.approve account
        end.to raise_error Errors::DomainError, "pending transaction id=(#{subject.aggregate_id}) has been rejected."
      end

      it 'should report income' do
        allow(account).to receive(:report_income)
        make_reported subject, user, account_id: account.aggregate_id, type_id: Domain::Transaction::IncomeTypeId
        subject.approve account
        expect(account).to have_received(:report_income).with(subject.aggregate_id, subject.amount, subject.date, subject.tag_ids, subject.comment)
      end

      it 'should report expense' do
        allow(account).to receive(:report_expense)
        make_reported subject, user, account_id: account.aggregate_id, type_id: Domain::Transaction::ExpenseTypeId
        subject.approve account
        expect(account).to have_received(:report_expense).with(subject.aggregate_id, subject.amount, subject.date, subject.tag_ids, subject.comment)
      end

      it 'should report refund' do
        allow(account).to receive(:report_refund)
        make_reported subject, user, account_id: account.aggregate_id, type_id: Domain::Transaction::RefundTypeId
        subject.approve account
        expect(account).to have_received(:report_refund).with(subject.aggregate_id, subject.amount, subject.date, subject.tag_ids, subject.comment)
      end

      it 'should fail if unknown type_id' do
        make_reported subject, user, account_id: account.aggregate_id, type_id: 999
        expect { subject.approve account }.to raise_error Errors::DomainError, 'unknown type: 999'
      end

      it 'should raise approved event' do
        make_reported subject, user, account_id: account.aggregate_id
        subject.approve account
        expect(subject).to have_one_uncommitted_event PendingTransactionApproved, aggregate_id: subject.aggregate_id
      end
    end

    describe 'approve_transfer' do
      let(:account) { Domain::Account.new.make_created 'account-100' }
      let(:receiving_account) { Domain::Account.new.make_created 'account-110' }

      it 'should fail if account_id is empty' do
        subject.report user, 't-100', '10.5'
        expect { subject.approve_transfer account, receiving_account, '100.30' }.to raise_error Errors::DomainError, 'account_id is empty.'
      end

      it 'should fail if receiving_account is nil' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        expect { subject.approve_transfer account, nil, '100.30' }.to raise_error Errors::DomainError, 'receiving_account is nil.'
      end

      it 'should fail if amount_received is empty' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        expect { subject.approve_transfer account, receiving_account, nil }.to raise_error Errors::DomainError, 'amount_received is empty.'
      end

      it 'should fail if account is wrong' do
        subject.report user, 't-100', '10.5', account_id: 'account-101'
        expect { subject.approve_transfer account, receiving_account, '100.30' }
          .to raise_error Errors::DomainError, "account is wrong. Expected account='account-101' but was account='account-100'."
      end

      it 'should fail if already approved' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        subject.apply_event PendingTransactionApproved.new subject.aggregate_id
        expect { subject.approve_transfer account, receiving_account, '100.30' }
          .to raise_error Errors::DomainError, 'pending transaction id=(t-100) has already been approved.'
      end

      it 'should fail if rejected' do
        subject.report user, 't-100', '10.5', account_id: account.aggregate_id
        subject.apply_event PendingTransactionRejected.new subject.aggregate_id
        expect do
          subject.approve_transfer account, receiving_account, '100.30'
        end.to raise_error Errors::DomainError, "pending transaction id=(#{subject.aggregate_id}) has been rejected."
      end

      it 'should preform the transfer' do
        make_reported subject, user, account_id: account.aggregate_id
        expect(CommonDomain::Aggregate).to receive(:new_id) { 'rt-220' }
        expect(account).to receive(:send_transfer).with(subject.aggregate_id, receiving_account.aggregate_id,
                                                        subject.amount, subject.date, subject.tag_ids, subject.comment) { 'st-221' }
        expect(receiving_account).to receive(:receive_transfer).with('rt-220', account.aggregate_id, 'st-221', '3693.50',
                                                                     subject.date, subject.tag_ids, subject.comment)
        subject.approve_transfer account, receiving_account, '3693.50'
      end

      it 'should raise approved event' do
        make_reported subject, user, account_id: account.aggregate_id
        subject.approve_transfer account, receiving_account, '100.30'
        expect(subject).to have_one_uncommitted_event PendingTransactionApproved, aggregate_id: subject.aggregate_id
      end
    end

    it 'should set approved flag on PendingTransactionApproved event' do
      subject.apply_event PendingTransactionApproved.new subject.aggregate_id
      expect(subject.is_approved).to be_truthy
    end

    describe 'reject' do
      it 'should raise rejected event' do
        subject.reject
        expect(subject).to have_one_uncommitted_event PendingTransactionRejected, aggregate_id: subject.aggregate_id
      end

      it 'should be idempotent' do
        subject.apply_event PendingTransactionRejected.new subject.aggregate_id
        subject.reject
        expect(subject).not_to have_uncommitted_events
      end

      it 'should set rejected flag on rejected' do
        subject.apply_event PendingTransactionRejected.new subject.aggregate_id
        expect(subject.is_rejected).to be_truthy
      end
    end

    describe 'restore' do
      let(:account) { Domain::Account.new.make_created 'account-100' }

      before(:each) do
        make_reported subject, user, transaction_id: 't-101', amount: '1003.32', date: date, tag_ids: ['t-1', 't-2'],
                                     comment: 'Transaction 101', account_id: account.aggregate_id, type_id: Domain::Transaction::IncomeTypeId
      end

      it 'should fail if transaction has been already approved' do
        subject.approve account
        expect { subject.restore }.to raise_error Errors::DomainError, 'approved transaction can not be restored'
      end

      it 'should raise no events if not rejected' do
        subject.restore
        expect(subject).not_to have_uncommitted_events
      end

      it 'should raise rejected event' do
        subject.apply_event PendingTransactionRejected.new(subject.aggregate_id)
        subject.restore
        expect(subject).to have_one_uncommitted_event PendingTransactionRestored,
                                                      aggregate_id: 't-101',
                                                      user_id: user.id,
                                                      amount: '1003.32',
                                                      date: date,
                                                      tag_ids: ['t-1', 't-2'],
                                                      comment: 'Transaction 101',
                                                      account_id: account.aggregate_id,
                                                      type_id: Domain::Transaction::IncomeTypeId
      end

      it 'should reset rejected flag on restored' do
        subject.apply_event PendingTransactionRejected.new(subject.aggregate_id)
        subject.apply_event PendingTransactionRestored.new(aggregate_id: 't-101',
                                                           user_id: user.id,
                                                           amount: '1003.32',
                                                           date: date,
                                                           tag_ids: ['t-1', 't-2'],
                                                           comment: 'Transaction 101',
                                                           account_id: account.aggregate_id,
                                                           type_id: Domain::Transaction::IncomeTypeId)
        expect(subject.is_rejected).to be_falsy
      end
    end
  end
end
