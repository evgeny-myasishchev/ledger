require 'rails_helper'

RSpec.describe App::AccountsService, :type => :model do
  let(:repository) { double(:repository) }
  subject { described_class.new repository }
  let(:c) { Module.new do
    include App::Commands::AccountCommands
  end
  }
  
  describe "ReportImport" do
    let(:work) { @work }
    let(:account) { double(:account, report_income: nil)}
    before(:each) do
      @work = expect(repository).to begin_work
    end
    
    xit "should use account to report the income" do
      expect(work).to get_and_return_aggregate Domain::Account, 'account-112', account
      date = DateTime.now
      expect(account).to receive(:report_income).with('34632.30', date, ['t-1', 't-2'], 'Monthly income')
      subject.handle_message c::ReportIncome.new(account_id: 'account-112', ammount: '34632.30', date: date, tag_ids: ['t-1', 't-2'], comment: 'Monthly income')
    end
  end
end