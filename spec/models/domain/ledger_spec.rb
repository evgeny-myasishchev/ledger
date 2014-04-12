require 'spec_helper'

describe Domain::Ledger do
  describe "create" do
    it "should raise LedgerCreated event"
  end
  
  describe "rename" do
    it "should raise LedgerRenamed event"
  end
  
  describe "share" do
    it "should share LedgerShared event"
  end
  
  describe "add_account" do
    it "should create new account and return it"
    
    it "should raise account AccountAddedToLedger event"
  end
end