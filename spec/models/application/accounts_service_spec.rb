require 'rails_helper'

RSpec.describe Application::AccountsService, :type => :model do
  let(:repository) { double(:repository) }
  subject { described_class.new repository }
  let(:p) { Projections }
  let(:c) { Module.new do
    include Application::Commands::AccountCommands
  end
  }
  let(:work) { @work }
  let(:account) { double(:account, report_income: nil, report_expence: nil)}
  let(:sending_account) { double(:sending_account, aggregate_id: 'src-110') }
  let(:receiving_account) { double(:receiving_account, aggregate_id: 'dst-210') }
  
  before(:each) do
    @work = expect(repository).to begin_work
  end
  
  describe "RenameAccount" do
    it "should use the account to rename" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      expect(account).to receive(:rename).with('New Name 112')
      cmd = c::RenameAccount.new('account-112', name: 'New Name 112')
      subject.handle_message cmd
    end
  end
  
  describe "SetAccountUnit" do
    it "should use the account to set unit" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      expect(account).to receive(:set_unit).with('new-unit-1')
      cmd = c::SetAccountUnit.new('account-112', unit: 'new-unit-1')
      subject.handle_message cmd
    end
  end
  
  
  describe "ReportIncome" do
    it "should use account to report the income" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_income).with('34632.30', date, ['t-1', 't-2'], 'Monthly income')
      cmd = c::ReportIncome.new('account-112', amount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Monthly income')
      subject.handle_message cmd
    end
  end
  
  describe "ReportExpence" do
    it "should use account to report the expence" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_expence).with('34632.30', date, ['t-1', 't-2'], 'Food')
      subject.handle_message c::ReportExpence.new('account-112', amount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Food')
    end
  end
  
  describe "ReportRefund" do
    it "should use account to report the expence" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_refund).with('34632.30', date, ['t-1', 't-2'], 'Food')
      subject.handle_message c::ReportRefund.new('account-112', amount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Food')
    end
  end
    
  describe "ReportTransfer" do
    let(:date) { DateTime.now }
    before(:each) do
      expect(work).to get_and_return_aggregate Domain::Account, 'src-110', sending_account
      expect(work).to get_and_return_aggregate Domain::Account, 'dst-210', receiving_account
    end
    
    it "should use source and target accounts to perform transfer" do
      command = c::ReportTransfer.new('src-110', 
        receiving_account_id: 'dst-210',
        amount_sent: '44322.10',
        amount_received: '3693.50',
        date: date,
        tag_ids: ['t-1', 't-2'],
        comment: 'Food')
      expect(sending_account).to receive(:send_transfer).with('dst-210', '44322.10', date, ['t-1', 't-2'], 'Food') { 'st-221' }
      expect(receiving_account).to receive(:receive_transfer).with('src-110', 'st-221', '3693.50', date, ['t-1', 't-2'], 'Food')
      subject.handle_message command
    end
  end
  
  describe "AdjustAmount" do
    it "should use the account to adjust the amount of the transaction" do
      expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { p::Transaction.new account_id: 'a-1' }
      expect(work).to get_and_return_aggregate Domain::Account, 'a-1', account
      expect(account).to receive(:adjust_amount).with('t-1', 221190)
      subject.handle_message c::AdjustAmount.new transaction_id: 't-1', command: {amount: 221190}
    end
  end
  
  describe "AdjustComment" do
    describe "regular transaction" do
      it "should get the transaction and use the account to adjust the comment" do
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { p::Transaction.new account_id: 'a-1' }
        expect(work).to get_and_return_aggregate Domain::Account, 'a-1', account
        expect(account).to receive(:adjust_comment).with('t-1', 'New comment')
        subject.handle_message c::AdjustComment.new transaction_id: 't-1', command: {comment: 'New comment'}
      end
    end
      
    describe "transfer transaction" do
      it "should get the transaction and use the account to adjust the comment" do
        sending = p::Transaction.new account_id: 'src-110', transaction_id: 't-1', is_transfer: true
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { sending }
        expect(sending).to receive(:get_transfer_counterpart) { p::Transaction.new account_id: 'dst-210', transaction_id: 't-2', is_transfer: true }
        expect(work).to get_and_return_aggregate Domain::Account, 'src-110', sending_account
        expect(work).to get_and_return_aggregate Domain::Account, 'dst-210', receiving_account
        expect(sending_account).to receive(:adjust_comment).with('t-1', 'New comment')
        expect(receiving_account).to receive(:adjust_comment).with('t-2', 'New comment')
        subject.handle_message c::AdjustComment.new transaction_id: 't-1', command: {comment: 'New comment'}
      end
    end
  end  
  
  describe "AdjustDate" do
    describe "regular transaction" do
      it "should get the transaction and use the account to adjust the date" do
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { p::Transaction.new account_id: 'a-1' }
        expect(work).to get_and_return_aggregate Domain::Account, 'a-1', account
        expect(account).to receive(:adjust_date).with('t-1', 'new-date')
        subject.handle_message c::AdjustDate.new transaction_id: 't-1', command: {date: 'new-date'}
      end
    end
      
    describe "transfer transaction" do
      it "should get the transaction and use the account to adjust the comment" do
        sending = p::Transaction.new account_id: 'src-110', transaction_id: 't-1', is_transfer: true
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { sending }
        expect(sending).to receive(:get_transfer_counterpart) { p::Transaction.new account_id: 'dst-210', transaction_id: 't-2', is_transfer: true }
        expect(work).to get_and_return_aggregate Domain::Account, 'src-110', sending_account
        expect(work).to get_and_return_aggregate Domain::Account, 'dst-210', receiving_account
        expect(sending_account).to receive(:adjust_date).with('t-1', 'New comment')
        expect(receiving_account).to receive(:adjust_date).with('t-2', 'New comment')
        subject.handle_message c::AdjustDate.new transaction_id: 't-1', command: {date: 'New comment'}
      end
    end
  end
    
  describe "AdjustTags" do
    describe "regular transaction" do
      it "should get the transaction and use the account to adjust the date" do
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { p::Transaction.new account_id: 'a-1' }
        expect(work).to get_and_return_aggregate Domain::Account, 'a-1', account
        expect(account).to receive(:adjust_tags).with('t-1', [100, 110])
        subject.handle_message c::AdjustTags.new transaction_id: 't-1', command: {tag_ids: [100, 110]}
      end
    end
      
    describe "transfer transaction" do
      it "should get the transaction and use the account to adjust the comment" do
        sending = p::Transaction.new account_id: 'src-110', transaction_id: 't-1', is_transfer: true
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { sending }
        expect(sending).to receive(:get_transfer_counterpart) { p::Transaction.new account_id: 'dst-210', transaction_id: 't-2', is_transfer: true }
        expect(work).to get_and_return_aggregate Domain::Account, 'src-110', sending_account
        expect(work).to get_and_return_aggregate Domain::Account, 'dst-210', receiving_account
        expect(sending_account).to receive(:adjust_tags).with('t-1', [100, 110])
        expect(receiving_account).to receive(:adjust_tags).with('t-2', [100, 110])
        subject.handle_message c::AdjustTags.new transaction_id: 't-1', command: {tag_ids: [100, 110]}
      end
    end
  end
  
  describe "RemoveTransaction" do
    describe "regular transaction" do
      it "should get the transaction and use the account to remove it" do
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { p::Transaction.new account_id: 'a-1' }
        expect(work).to get_and_return_aggregate Domain::Account, 'a-1', account
        expect(account).to receive(:remove_transaction).with('t-1')
        subject.handle_message c::RemoveTransaction.new id: 't-1'
      end
    end
      
    describe "transfer transaction" do
      it "should get the transaction and remove both counterparts" do
        sending = p::Transaction.new account_id: 'src-110', transaction_id: 't-1', is_transfer: true
        expect(p::Transaction).to receive(:find_by_transaction_id).with('t-1') { sending }
        expect(sending).to receive(:get_transfer_counterpart) { p::Transaction.new account_id: 'dst-210', transaction_id: 't-2', is_transfer: true }
        expect(work).to get_and_return_aggregate Domain::Account, 'src-110', sending_account
        expect(work).to get_and_return_aggregate Domain::Account, 'dst-210', receiving_account
        expect(sending_account).to receive(:remove_transaction).with('t-1')
        expect(receiving_account).to receive(:remove_transaction).with('t-2')
        subject.handle_message c::RemoveTransaction.new id: 't-1'
      end
    end
  end

end