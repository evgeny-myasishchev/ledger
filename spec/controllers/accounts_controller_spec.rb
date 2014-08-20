require 'rails_helper'

RSpec.describe AccountsController, :type => :controller do
  let(:i) {
    Module.new do
      include Application::Commands::LedgerCommands
      include Application::Commands::AccountCommands
      include CommonDomain::Infrastructure
    end
  }
  include AuthenticationHelper
  authenticate_user
  
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
        
    it "routes ledgers nested reopen route" do
      expect({post: 'ledgers/22331/accounts/33322/reopen'}).to route_to controller: 'accounts', action: 'reopen', ledger_id: '22331', account_id: '33322'
    end
    
    it "routes ledgers nested delete route" do
      expect({delete: 'ledgers/22331/accounts/33322'}).to route_to controller: 'accounts', action: 'destroy', ledger_id: '22331', account_id: '33322'
    end
    
    it "routes rename" do
      expect({put: 'accounts/33223/rename'}).to route_to controller: 'accounts', action: 'rename', aggregate_id: '33223'
    end
    
    it "routes ledgers nested set-category route" do
      expect({put: 'ledgers/22331/accounts/33322/set-category'}).to route_to controller: 'accounts', action: 'set_category', ledger_id: '22331', account_id: '33322'
    end
  end
  
  describe "GET 'new'" do
    it "should load and assign known currencies" do
      known_currencies = double(:known_currencies)
      expect(Currency).to receive(:known).and_return(known_currencies)
      get :new, ledger_id: 221, format: :json
      expect(response.status).to eql 200
      expect(assigns(:currencies)).to be known_currencies
    end
      
    it "should generate and assign new account_id" do
      expect(i::AggregateId).to receive(:new_id).and_return('new-account-223')
      get :new, ledger_id: 221, format: :json
      expect(response.status).to eql 200
      expect(assigns(:new_account_id)).to eql 'new-account-223'
    end
  end
  
  describe "ledger nested actions" do
    def should_dispatch verb, action, command_class
      command = double(:command)
      expect(command_class).to receive(:new) do |aggregate_id, params|
        expect(aggregate_id).to eql 'ledger-221'
        expect(params).to be controller.params
        command
      end
      expect(controller).to receive(:dispatch_command).with(command)
      send verb, action, ledger_id: 'ledger-221', account_id: 'account-9932', key1: 'value-1', key2: 'value-2'
      expect(response.status).to eql 200
    end
    
    it "should disaptch create command on POST 'create'" do
      should_dispatch :post, 'create', i::CreateNewAccount
    end
    
    it "should disaptch close command on POST 'close'" do
      should_dispatch :post, 'close', i::CloseAccount
    end
    
    it "should disaptch reopen command on POST 'reopen'" do
      should_dispatch :post, 'reopen', i::ReopenAccount
    end
    
    it "should disaptch remove command on DELETE 'destroy'" do
      should_dispatch :delete, 'destroy', i::RemoveAccount
    end
    
    it "should disaptch set category command on PUT 'set_category'" do
      should_dispatch :put, 'set_category', i::SetAccountCategory
    end
  end
  
  describe "PUT 'rename'" do
    it "should dispatch rename command" do
      command = double(:command)
      expect(i::RenameAccount).to receive(:from_hash) do |params|
        expect(params).to be controller.params
        command
      end
      expect(controller).to receive(:dispatch_command).with(command)
      put 'rename', aggregate_id: 'account-223', key1: 'value-1', key2: 'value-2'
      expect(response.status).to eql 200
    end
  end
end
