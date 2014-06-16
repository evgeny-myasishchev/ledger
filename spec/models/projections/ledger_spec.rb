require 'rails_helper'

RSpec.describe Projections::Ledger, :type => :model do
  subject { described_class.create_projection }
  
  before(:each) do
    subject.handle_message Domain::Events::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
  end
  
  let(:ledger_1) { ledger = described_class.find_by_aggregate_id 'ledger-1' }
  
  describe "LedgerCreated" do
    it "should create corresponding ledger record" do
      ledger_1 = described_class.find_by aggregate_id: 'ledger-1'
      expect(ledger_1.name).to eql 'Ledger 1'
      expect(ledger_1.owner_user_id).to eql 100
    end
    
    it "should be idempotent" do
      expect { subject.handle_message Domain::Events::LedgerCreated.new 'ledger-1', 100, 'Ledger 1' }.not_to change { described_class.count }
    end
  end
  
  describe "LedgerRenamed" do
    it "should rename the ledger" do
      subject.handle_message Domain::Events::LedgerRenamed.new 'ledger-1', 'Ledger 110'
    end
  end
  
  describe "LedgerShared" do
    before(:each) do
      subject.handle_message Domain::Events::LedgerShared.new 'ledger-1', 120
      subject.handle_message Domain::Events::LedgerShared.new 'ledger-1', 130
    end
    
    it "should record corresponding user_id" do
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
    
    it "should be idempotent" do
      subject.handle_message Domain::Events::LedgerShared.new 'ledger-1', 120
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
  end
end
