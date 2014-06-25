require 'rails_helper'

describe HomeController do
  describe "routes", :type => :routing do
    it "routes root to home/index" do
      expect({get: '/'}).to route_to controller: 'home', action: 'index'
    end
  end

  describe "GET 'index'" do
    describe "not authenticated" do
      it "redirects to new session url" do
        get 'index'
        expect(response).to be_redirect
        expect(response).to redirect_to(new_user_session_url)
      end
    end
    
    describe "authenticated" do
      include AuthenticationHelper
      authenticate_user
      it "should load accounts for given user" do
        accounts = double(:accounts)
        expect(Projections::Account).to receive(:get_user_accounts).with(user).and_return(accounts)
        get 'index'
        expect(response.status).to eql 200
        expect(assigns(:accounts)).to be accounts
      end
    end
  end
end
