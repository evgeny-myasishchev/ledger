require 'rails_helper'

RSpec.describe Api::SessionsController, :type => :controller do

  describe "routes", :type => :routing do
    it "routes POST create session" do
      expect({post: 'api/sessions'}).to route_to controller: 'api/sessions', action: 'create'
    end
  end
  
  describe "POST create" do
    it 'should return authenticity token' do
      post :create, format: :json
      expect(response).to have_http_status(:success)
      body_json = JSON.parse response.body
      expect(body_json['form_authenticity_token']).to eql session[:_csrf_token]
    end
  end
end
