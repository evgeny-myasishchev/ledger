require 'rails_helper'

RSpec.describe Projections::Account, :type => :model do
  
  describe "projection" do
    subject { described_class.create_projection }
    let(:e) { Domain::Events }
  
    before(:each) do
      subject.handle_message e::AccountCreated.new 'account-223', 'ledger-1', 'Account 223', 'UAH'
    end
    let(:account_223) { described_class.find_by_aggregate_id 'account-223' }
    describe "on AccountCreated" do
      it "should create corresponding record" do
        expect(account_223).not_to be_nil
        expect(account_223.ledger_id).to eql 'ledger-1'
        expect(account_223.currency_code).to eql 'UAH'
        expect(account_223.name).to eql 'Account 223'
        expect(account_223.balance).to eql 0
        expect(account_223.is_closed).to be_falsey
      end
    
      it "should be idempotent" do
        expect { subject.handle_message e::AccountCreated.new 'account-223', 'ledger-1', 'Account 223', 'UAH' }.not_to change { described_class.count }
      end
    end
  
    describe "on AccountRenamed" do
      it "should update the name" do
        subject.handle_message e::AccountRenamed.new 'account-223', 'New Name 223'
        expect(account_223.name).to eql 'New Name 223'
      end
    end
  
    describe "on AccountClosed" do
      it "should mark the account as closed" do
        subject.handle_message e::AccountClosed.new 'account-223'
        expect(account_223.is_closed).to be_truthy
      end
    end
  end
end
