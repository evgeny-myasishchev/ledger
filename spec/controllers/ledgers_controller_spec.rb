require 'rails_helper'

RSpec.describe LedgersController, :type => :controller do
  include AuthenticationHelper
  authenticate_user
  
  describe "routes", :type => :routing do
    it "routes GET 'currency-rates'" do
      expect({get: 'ledgers/22331/currency-rates'}).to route_to controller: 'ledgers', action: 'currency_rates', ledger_id: '22331'
    end
  end
  
  describe 'GET "currency-rates"' do
    it 'should use ledger projection to get rates' do
      rates = double(:rates)
      expect(Projections::Ledger).to receive(:get_rates).with(user, '22332').and_return(rates)
      get 'currency_rates', ledger_id: '22332', format: :json
      expect(response.status).to eql 200
      expect(assigns(:rates)).to eql rates
    end
  end
end
