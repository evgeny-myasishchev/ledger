require 'rails_helper'

RSpec.describe Projections::Transaction, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expence_id) { Domain::Transaction::ExpenceTypeId }
  
  
  describe "on TransactionReported" do
    it "should record the transaction" do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', income_id, 10523, 22003, date1, ['t-1', 't-2'], 'Comment 100'
      subject.handle_message e::TransactionReported.new 'account-1', 't-2', expence_id, 2000, 20003, date2, ['t-3', 't-4'], 'Comment 101'
      
      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(income_id)
      expect(t1.ammount).to eql(10523)
      expect(t1.balance).to eql(22003)
      expect(t1.tag_ids).to eql Set.new(['t-1', 't-2'])
      expect(t1.comment).to eql 'Comment 100'
      expect(t1.date.to_datetime).to eql date1.utc
            
      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2.account_id).to eql('account-1')
      expect(t2.type_id).to eql(expence_id)
      expect(t2.ammount).to eql(2000)
      expect(t2.balance).to eql(20003)
      expect(t2.tag_ids).to eql Set.new(['t-3', 't-4'])
      expect(t2.comment).to eql 'Comment 101'
      expect(t2.date.to_datetime).to eql date2.utc
    end
  end
end
