require 'rails_helper'

RSpec.describe Projections::Tags, :type => :model do
  describe "on TagCreated" do
    it "should insert a new tag"
  end
  
  describe "on TagRenamed" do
    it "should rename the tag"
  end
    
  describe "on TagRemoved" do
    it "should mark the tag as removed"
  end
end
