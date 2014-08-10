require 'rails_helper'

RSpec.describe AccountsController, :type => :controller do
  let(:cmd) { Application::Commands::AccountCommands }
  include AuthenticationHelper
  
  describe "routes", :type => :routing do
    it "routes ledgers nested new route" do
      expect({get: 'ledgers/22331/accounts/new'}).to route_to controller: 'accounts', action: 'new', ledger_id: '22331'
    end
    
    it "routes ledgers nested create route" do
      expect({post: 'ledgers/22331/accounts'}).to route_to controller: 'accounts', action: 'create', ledger_id: '22331'
    end
    
    it "routes ledgers nested close route" do
      expect({post: 'ledgers/22331/accounts/33322/close'}).to route_to controller: 'accounts', action: 'close', ledger_id: '22331', account_id: '33322'
    end
    
    it "routes rename" do
      expect({put: 'accounts/33223/rename'}).to route_to controller: 'accounts', action: 'rename', aggregate_id: '33223'
    end
  end
end
