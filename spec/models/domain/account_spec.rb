require 'spec_helper'

describe Domain::Account do
  describe "create" do
    it "should raise AccountCreated event"
  end
  
  describe "create" do
    it "should raise AccountRenamed event"
  end
  
  describe "report_income" do
    it "should raise TransactionReported event"
  end
    
  describe "report_expence" do
    it "should raise TransactionReported event"
  end
  
  describe "adjust_ammount" do
    it "should raise TransactionAmmountAdjusted"
  end
  
  describe "adjust_comment" do
    it "should raise TransactionCommentAdjusted"
  end
  
  describe "add_tag" do
    it "should raise TransactionTagAdded"
  end
  
  describe "remove_tag" do
    it "should raise TransactionTagRemoved"
  end
end