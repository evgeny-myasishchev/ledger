require 'rails_helper'

RSpec.describe Application::LedgersService, :type => :model do
  let(:repository) { double(:repository) }
  subject { described_class.new repository }
  let(:i) {
    Module.new do
      include Projections
      include Application::Commands
    end
  }
  let(:ledger1) { double(:ledger1, aggregate_id: 'ledger-1') }
  let(:work) { @work }
  
  before(:each) do
    @work = expect(repository).to begin_work
  end
  
  describe "CreateNewAccount" do
    it "use the ledger to create the account" do
      cmd = i::LedgerCommands::CreateNewAccount.new 'ledger-1', 
        account_id: 'account-1332',
        name: 'Account 1223',
        initial_balance: '100.23',
        currency_code: 'UAH'
      initial_data = Domain::Account::InitialData.new('Account 1223', '100.23', Currency['UAH'])
      expect(work).to get_and_return_aggregate Domain::Ledger, 'ledger-1', ledger1
      account = double(:account)
      expect(ledger1).to receive(:create_new_account).with('account-1332', initial_data).and_return(account)
      expect(work).to receive(:add_new).with(account)
      subject.handle_message cmd
    end
  end
end