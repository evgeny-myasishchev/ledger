require 'rails_helper'

RSpec.describe Application::AccountsService, :type => :model do
  let(:repository) { double(:repository) }
  subject { described_class.new repository }
  let(:c) { Module.new do
    include Application::Commands::AccountCommands
  end
  }
  let(:work) { @work }
  let(:account) { double(:account, report_income: nil, report_expence: nil)}
  
  describe "ReportIncome" do
    before(:each) do
      @work = expect(repository).to begin_work
    end
    
    it "should use account to report the income" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_income).with('34632.30', date, ['t-1', 't-2'], 'Monthly income')
      cmd = c::ReportIncome.new('account-112', ammount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Monthly income')
      subject.handle_message cmd
    end
  end
  
  describe "ReportExpence" do
    before(:each) do
      @work = expect(repository).to begin_work
    end
    
    it "should use account to report the expence" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_expence).with('34632.30', date, ['t-1', 't-2'], 'Food')
      subject.handle_message c::ReportExpence.new('account-112', ammount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Food')
    end
  end
  
  describe "ReportRefund" do
    before(:each) do
      @work = expect(repository).to begin_work
    end
    
    it "should use account to report the expence" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_refund).with('34632.30', date, ['t-1', 't-2'], 'Food')
      subject.handle_message c::ReportRefund.new('account-112', ammount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Food')
    end
  end
end