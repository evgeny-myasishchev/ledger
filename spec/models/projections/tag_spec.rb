require 'rails_helper'

RSpec.describe Projections::Tag, :type => :model do
  subject { described_class.create_projection }
  let(:p) { Projections }
  let(:e) { Domain::Events }

  before(:each) do
    p::Ledger.create!(aggregate_id: 'ledger-1', owner_user_id: 22331, shared_with_user_ids: Set.new([22332, 22333]), name: 'ledger 1')
    p::Ledger.create!(aggregate_id: 'ledger-2', owner_user_id: 23331, shared_with_user_ids: Set.new([23332, 23333]), name: 'ledger 2')
    subject.handle_message e::TagCreated.new 'ledger-1', 1, 'tag-1'
    subject.handle_message e::TagCreated.new 'ledger-1', 2, 'tag-2'
    subject.handle_message e::TagCreated.new 'ledger-1', 3, 'tag-3'

    subject.handle_message e::TagCreated.new 'ledger-2', 1, 'tag-1'
    subject.handle_message e::TagCreated.new 'ledger-2', 2, 'tag-2'
  end

  describe "on TagCreated" do
    it "should insert a new tag" do
      expect(described_class.where(ledger_id: 'ledger-1').count).to eql 3
      expect(described_class.where(ledger_id: 'ledger-2').count).to eql 2

      tag_1 = described_class.find_by ledger_id: 'ledger-1', tag_id: 1
      expect(tag_1.name).to eql 'tag-1'

      tag_2 = described_class.find_by ledger_id: 'ledger-1', tag_id: 2
      expect(tag_2.name).to eql 'tag-2'
    end

    it "should assign authorized users" do
      tag_11 = described_class.find_by ledger_id: 'ledger-1', tag_id: 1
      expect(tag_11.authorized_user_ids).to eql('{22332},{22333},{22331}')

      tag_21 = described_class.find_by ledger_id: 'ledger-2', tag_id: 1
      expect(tag_21.authorized_user_ids).to eql('{23332},{23333},{23331}')
    end
  end

  describe "on TagRenamed" do
    it "should rename the tag" do
      subject.handle_message e::TagRenamed.new 'ledger-1', 1, 'tag-1-renamed'
      subject.handle_message e::TagRenamed.new 'ledger-1', 3, 'tag-3-renamed'
      expect(described_class.find_by(ledger_id: 'ledger-1', tag_id: 1).name).to eql 'tag-1-renamed'
      expect(described_class.find_by(ledger_id: 'ledger-1', tag_id: 3).name).to eql 'tag-3-renamed'
    end
  end

  describe "on TagRemoved" do
    it "should remove the tag" do
      subject.handle_message e::TagRemoved.new 'ledger-1', 1
      subject.handle_message e::TagRemoved.new 'ledger-1', 3
      expect(described_class.where(ledger_id: 'ledger-1').count).to eql 1
      expect(described_class.where(ledger_id: 'ledger-1', tag_id: 1).count).to eql 0
      expect(described_class.where(ledger_id: 'ledger-1', tag_id: 3).count).to eql 0
    end
  end
end
