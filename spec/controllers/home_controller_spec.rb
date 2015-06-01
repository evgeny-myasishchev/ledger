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
      it "should get related data for given user" do
        ledgers = double(:ledgers)
        accounts = double(:accounts)
        tags = double(:tags)
        categories = double(:categories)
        expect(Projections::Ledger).to receive(:get_user_ledgers).with(user).and_return(ledgers)
        expect(Projections::Account).to receive(:get_user_accounts).with(user).and_return(accounts)
        expect(Projections::Tag).to receive(:get_user_tags).with(user).and_return(tags)
        expect(Projections::Category).to receive(:get_user_categories).with(user).and_return(categories)
        expect(Projections::PendingTransaction).to receive(:get_pending_transactions_count).with(user).and_return(223)
        get 'index'
        expect(response.status).to eql 200
        expect(assigns(:ledgers)).to be ledgers
        expect(assigns(:accounts)).to be accounts
        expect(assigns(:tags)).to be tags
        expect(assigns(:categories)).to be categories
        expect(assigns(:pending_transactions_count)).to eql 223
      end
    end
  end
end
