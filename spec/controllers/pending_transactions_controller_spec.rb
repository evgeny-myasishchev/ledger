require 'rails_helper'

RSpec.describe PendingTransactionsController, :type => :controller do
  describe "routes", :type => :routing do
    it "routes POST 'report'" do
      expect({post: 'pending-transactions'}).to route_to controller: 'pending_transactions', action: 'report'
    end
    
    it "routes PUT 'adjust'" do
      expect({put: 'pending-transactions/t-110'}).to route_to controller: 'pending_transactions', action: 'adjust', aggregate_id: 't-110'
    end
    
    it "routes POST 'approve'" do
      expect({post: 'pending-transactions/t-110/approve'}).to route_to controller: 'pending_transactions', action: 'approve', aggregate_id: 't-110'
    end
  end
end
