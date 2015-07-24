require 'rails_helper'

RSpec.describe Application::PendingTransactionsService, :type => :model do
  include DummyEventStore
  let(:repository) { repository_factory.repository }
  let(:repository_factory) { create_dummy_repo_factory }
  subject { described_class.new repository_factory }
  let(:c) { Module.new do
    include Application::Commands::PendingTransactionCommands
  end
  }
  
  let(:pt) { double(:pending_transaction, aggregate_id: 'pt-223') }
  
  describe "ReportPendingTransaction" do
    let(:user) { User.new id: 1332 }
    it "should report new pending transaction" do
      cmd = c::ReportPendingTransaction.new id: 'pt-223', user: user, amount: '100.33', date: DateTime.now, 
        tag_ids: ['t-1', 't-2'], comment: 'Transaction 223', account_id: 'a-110', 
        type_id: 2, headers: dummy_headers
      expect(Domain::PendingTransaction).to receive(:new) { pt }
      expect(pt).to receive(:report).with(cmd.user, cmd.id, cmd.amount,
        date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment,
        account_id: cmd.account_id, type_id: cmd.type_id)
      expect(repository).to receive(:save).with(pt, with_dummy_headers, with_dummy_transaction_context)
      subject.handle_message cmd
    end
  end
  
  describe 'AdjustPendingTransaction' do
    it "should adjust pending transaction" do
      cmd = c::AdjustPendingTransaction.new id: 'pt-223', amount: '100.33', date: DateTime.now, 
        tag_ids: ['t-1', 't-2'], comment: 'Transaction 223', account_id: 'a-110', 
        type_id: 2, headers: dummy_headers
      expect(repository).to get_by_id(Domain::PendingTransaction, 'pt-223').and_return(pt).and_save(with_dummy_headers)
      expect(pt).to receive(:adjust).with(amount: cmd.amount, date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment,
        account_id: cmd.account_id, type_id: cmd.type_id)
      subject.handle_message cmd
    end
  end
  
  describe 'ApprovePendingTransaction' do
    let(:account) { double(:account, aggregate_id: 'a-101') }
    before do
      allow(pt).to receive(:account_id) { account.aggregate_id }
    end
    it 'should approve the pending transaction' do
      cmd = c::ApprovePendingTransaction.new id: 'pt-223', headers: dummy_headers
      expect(repository).to get_by_id(Domain::PendingTransaction, 'pt-223').and_return(pt).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(repository).to get_by_id(Domain::Account, account.aggregate_id).and_return(account).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(pt).to receive(:approve).with(account)
      subject.handle_message cmd
    end
  end
  
  describe 'AdjustAndApprovePendingTransaction' do
    let(:account) { double(:account, aggregate_id: 'a-101') }
    before do
      allow(pt).to receive(:account_id) { account.aggregate_id }
    end
    it 'should approve the pending transaction' do
      cmd = c::AdjustAndApprovePendingTransaction.new id: 'pt-223', amount: '100.33', date: DateTime.now, 
        tag_ids: ['t-1', 't-2'], comment: 'Transaction 223', account_id: 'a-110', 
        type_id: 2, headers: dummy_headers
        
      expect(repository).to get_by_id(Domain::PendingTransaction, 'pt-223').and_return(pt).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(repository).to get_by_id(Domain::Account, account.aggregate_id).and_return(account).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(pt).to receive(:adjust).with(amount: cmd.amount, date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment,
        account_id: cmd.account_id, type_id: cmd.type_id)
      expect(pt).to receive(:approve).with(account)
      subject.handle_message cmd
    end
  end
  
  describe 'AdjustAndApprovePendingTransferTransaction' do
    let(:account) { double(:account, aggregate_id: 'a-110') }
    let(:receiving_account) { double(:receiving_account, aggregate_id: 'a-120') }
    before do
      allow(pt).to receive(:account_id) { account.aggregate_id }
    end
    it 'should approve the pending transaction' do
      cmd = c::AdjustAndApprovePendingTransferTransaction.new id: 'pt-223', amount: '100.33', date: DateTime.now, 
        tag_ids: ['t-1', 't-2'], comment: 'Transaction 223', account_id: 'a-110', 
        type_id: 2, receiving_account_id: 'a-120', amount_received: '844.33', headers: dummy_headers
        
      expect(repository).to get_by_id(Domain::PendingTransaction, 'pt-223').and_return(pt).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(repository).to get_by_id(Domain::Account, account.aggregate_id).and_return(account).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(repository).to get_by_id(Domain::Account, receiving_account.aggregate_id).and_return(receiving_account).and_save(with_dummy_headers, with_dummy_transaction_context)
      expect(pt).to receive(:adjust).with(amount: cmd.amount, date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment,
        account_id: cmd.account_id, type_id: cmd.type_id)
      expect(pt).to receive(:approve_transfer).with(account, receiving_account, cmd.amount_received)
      subject.handle_message cmd
    end
  end

  describe 'RejectPendingTransaction' do
    let(:account) { double(:account, aggregate_id: 'a-101') }
    
    it 'should reject the pending transaction' do
      cmd = c::RejectPendingTransaction.new id: 'pt-223', headers: dummy_headers
      expect(repository).to get_by_id(Domain::PendingTransaction, 'pt-223').and_return(pt).and_save(with_dummy_headers)
      expect(pt).to receive(:reject)
      subject.handle_message cmd
    end
  end
end