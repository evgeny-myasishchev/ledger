require 'spec_helper'

describe Domain::Ledger do
  module I
    include Domain::Events
  end
  
  it "should be an aggregate" do
    subject.should be_an_aggregate
  end
  
  describe "create" do
    it "should raise LedgerCreated event" do
      CommonDomain::Infrastructure::AggregateId.should_receive(:new_id).and_return('ledger-1')
      subject.create 100, 'Ledger 1'
      subject.should have_one_uncommitted_event I::LedgerCreated, user_id: 100, name: 'Ledger 1'
    end
    
    it "should assign the id on LedgerCreated" do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
      subject.aggregate_id.should eql 'ledger-1'
    end
  end
  
  describe "rename" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
    end
    
    it "should raise LedgerRenamed event" do
      subject.rename 'New Ledger 20'
      subject.should have_one_uncommitted_event I::LedgerRenamed, name: 'New Ledger 20'
    end
  end
  
  describe "share" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1'
    end
    
    it "should share LedgerShared event" do
      subject.share 200
      subject.should have_one_uncommitted_event I::LedgerShared, user_id: 200
    end
        
    it "should not share if already shared" do
      subject.apply_event I::LedgerShared.new 'ledger-1', 200
      subject.share 200
      subject.should_not have_uncommitted_events
    end
  end
  
  describe "add_account" do
    it "should create new account and return it"
    
    it "should raise account AccountAddedToLedger event"
  end
  
  describe "create_tag" do
    it "should raise TagCreatedEvent"
  end
  
  describe "rename_tag" do
    it "should raise TagRenamedEvent"
  end
  
  describe "remove_tag" do
    it "should raise TagRemovedEvent"
  end
end