require 'rails_helper'

RSpec.describe Projections::Transaction, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:dt) { Domain::Transaction }
  
  describe "on TransactionReported" do
    it "should record the transaction calculating the balance" do
      date = DateTime.now - 100
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', dt::IncomeTypeId, 10523, date, ['t-1', 't-2'], 'Comment 100'
      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(dt::IncomeTypeId)
      expect(t1.ammount).to eql(10523)
      expect(t1.balance).to eql(10523)
    end
  end
end
