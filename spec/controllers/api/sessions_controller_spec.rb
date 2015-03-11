require 'rails_helper'

RSpec.describe Api::SessionsController, :type => :controller do

  describe "routes", :type => :routing do
    it "routes GET new session" do
      expect({get: 'api/sessions/new'}).to route_to controller: 'api/sessions', action: 'new'
    end
  end

  describe "GET new" do
    it "returns http success" do
      get :new, format: :json
      expect(response).to have_http_status(:success)
      body_json = JSON.parse response.body
      expect(body_json['form_authenticity_token']).to eql session[:_csrf_token]
    end
  end

end
