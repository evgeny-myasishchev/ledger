require 'rails_helper'

RSpec.describe CategoriesController, :type => :controller do
  let(:i) {
    Module.new do
      include Application::Commands::LedgerCommands
    end
  }
  
  include AuthenticationHelper
  authenticate_user
  
  describe "routes", :type => :routing do
    it "routes ledgers nested create route" do
      expect({post: 'ledgers/22331/categories'}).to route_to controller: 'categories', action: 'create', ledger_id: '22331'
    end
    
    it "routes ledgers nested update route" do
      expect({put: 'ledgers/22331/categories/910'}).to route_to controller: 'categories', action: 'update', ledger_id: '22331', category_id: '910'
    end
    
    it "routes ledgers nested destroy route" do
      expect({delete: 'ledgers/22331/categories/910'}).to route_to controller: 'categories', action: 'destroy', ledger_id: '22331', category_id: '910'
    end
  end
  
  describe "ledger nested actions" do
    def should_dispatch verb, action, command_class
      command = double(:command)
      expect(command_class).to receive(:new) do |params|
        expect(params).to be controller.params
        command
      end
      expect(controller).to receive(:dispatch_command).with(command)
      send verb, action, ledger_id: 'ledger-221', category_id: 'account-9932', key1: 'value-1', key2: 'value-2'
      expect(response.status).to eql 200
    end
    
    it "should disaptch create command on POST 'create'" do
      should_dispatch :post, 'create', i::CreateCategory
    end
    
    it "should return category_id when created" do
      expect(controller).to receive(:dispatch_command) { 332290 }
      post :create, ledger_id: 'ledger-221', name: 'New tag'
      expect(response.body).to eql({category_id: 332290}.to_json)
    end
    
    it "should disaptch rename command on PUT 'update'" do
      should_dispatch :put, 'update', i::RenameCategory
    end
    
    it "should disaptch remove command on DELETE 'destroy'" do
      should_dispatch :delete, 'destroy', i::RemoveCategory
    end
  end
end
