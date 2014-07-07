require 'rails_helper'

describe TransactionsController do
  describe "routes", :type => :routing do
    it "routes nested index route" do
      expect({get: 'accounts/22331/transactions'}).to route_to controller: 'transactions', action: 'index', account_id: '22331'
      expect(account_transactions_path('22331')).to eql '/accounts/22331/transactions'
    end
    
    it "routes POST 'report-income'" do
      expect({post: 'accounts/22331/transactions/report-income'}).to route_to controller: 'transactions', action: 'report_income', account_id: '22331'
    end
    
    it "routes POST 'report-expence'" do
      expect({post: 'accounts/22331/transactions/report-expence'}).to route_to controller: 'transactions', action: 'report_expence', account_id: '22331'
    end
  end
  
  describe "GET 'index'" do
    describe "not authenticated" do
      it "redirects to new session url" do
        get 'index', account_id: 'a-100'
        expect(response).to be_redirect
        expect(response).to redirect_to(new_user_session_url)
      end
    end
    
    describe "authenticated" do
      include AuthenticationHelper
      authenticate_user
      it "should get transactions for given account" do
        transactions = double(:transactions)
        expect(Projections::Transaction).to receive(:get_account_transactions).with(user, 'a-100').and_return(transactions)
        get 'index', account_id: 'a-100', format: :json
        expect(response.status).to eql 200
        expect(assigns(:transactions)).to be transactions
      end
    end
  end
end
