require 'rails_helper'

RSpec.describe Projections::Ledger, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:p) { Projections }

  before(:each) do
    subject.handle_message e::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
  end
  
  let(:ledger_1) { ledger = described_class.find_by_aggregate_id 'ledger-1' }
  
  describe "self.get_user_ledgers" do
    it "should return ledgers owed by the user" do
      l1 = p::Ledger.create! aggregate_id: 'l-1', owner_user_id: 11222, name: 'Ledger 1', shared_with_user_ids: nil
      l2 = p::Ledger.create! aggregate_id: 'l-2', owner_user_id: 11222, name: 'Ledger 2', shared_with_user_ids: nil
      l3 = p::Ledger.create! aggregate_id: 'l-3', owner_user_id: 11223, name: 'Ledger 3', shared_with_user_ids: nil
      expect(p::Ledger.get_user_ledgers(User.new id: 11222)).to eql([l1, l2])
      expect(p::Ledger.get_user_ledgers(User.new id: 11223)).to eql([l3])
    end
    
    it "should load limited set of attributes only" do
      l1 = p::Ledger.create! aggregate_id: 'l-1', owner_user_id: 11222, name: 'Ledger 1', shared_with_user_ids: nil
      actual_l1 = p::Ledger.get_user_ledgers(User.new id: 11222).first
      expect(actual_l1.attribute_names).to eql ['id', 'aggregate_id', 'name']
    end
  end
  
  describe "on LedgerCreated" do
    it "should create corresponding ledger record" do
      ledger_1 = described_class.find_by aggregate_id: 'ledger-1'
      expect(ledger_1.name).to eql 'Ledger 1'
      expect(ledger_1.owner_user_id).to eql 100
    end
    
    it "should be idempotent" do
      expect { subject.handle_message e::LedgerCreated.new 'ledger-1', 100, 'Ledger 1' }.not_to change { described_class.count }
    end
  end
  
  describe "on LedgerRenamed" do
    it "should rename the ledger" do
      subject.handle_message e::LedgerRenamed.new 'ledger-1', 'Ledger 110'
    end
  end
  
  describe "on LedgerShared" do
    before(:each) do
      subject.handle_message e::LedgerShared.new 'ledger-1', 120
      subject.handle_message e::LedgerShared.new 'ledger-1', 130
    end
    
    it "should record corresponding user_id" do
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
    
    it "should be idempotent" do
      subject.handle_message e::LedgerShared.new 'ledger-1', 120
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
  end

  describe "authorized_user_ids" do
    it "should return an array of all users that are authorized to access the ledger" do
      ledger = p::Ledger.create!(aggregate_id: 'ledger-2', owner_user_id: 22331, shared_with_user_ids: Set.new([22332, 22333]), name: 'ledger 1')
      expect(ledger.authorized_user_ids).to eql([22332, 22333, 22331])
    end
  end
end
