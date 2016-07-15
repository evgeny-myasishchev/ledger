require 'rails_helper'

RSpec.describe Api::SessionsController, type: :controller do
  describe 'routes', type: :routing do
    it 'routes POST create session' do
      expect(post: 'api/sessions').to route_to controller: 'api/sessions', action: 'create'
    end
  end

  describe 'POST create' do
    let(:dummy_user) { create(:user) }
    let(:raw_google_id_token) do
      "raw-google-id-token-#{SecureRandom.hex(5)}"
    end
    let(:token_data) do
      { 'email' => dummy_user.email }
    end
    let(:dummy_certificates) do
      [:cert1, :cert2, :cert3]
    end
    before(:each) do
      allow(AccessToken).to receive(:google_certificates) { dummy_certificates }
      allow(AccessToken).to receive(:extract).with(raw_google_id_token, dummy_certificates) { token_data }
    end

    it 'should return 401 if no google_id_token present in params' do
      post :create, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'should return 401 if the token is invalid' do
      allow(AccessToken).to receive(:extract).and_raise AccessToken::TokenError.new 'invalid token'
      post :create, format: :json, google_id_token: raw_google_id_token
      expect(response).to have_http_status(:unauthorized)
    end

    it 'should return 401 if no user with such email' do
      token_data['email'] = FFaker::Internet.email('not-existing-user')
      post :create, format: :json, google_id_token: raw_google_id_token
      expect(response).to have_http_status(:unauthorized)
    end

    it 'should authenticate the user based on the email from token' do
      expect(User).to receive(:find_by).with(email: dummy_user.email) { dummy_user }
      post :create, format: :json, google_id_token: raw_google_id_token
      expect(response).to have_http_status(:success)
      expect(controller.current_user).to be dummy_user
      expect(AccessToken).to have_received(:extract).with(raw_google_id_token, dummy_certificates)
    end

    it 'should return authenticity token' do
      expect(controller).to receive(:form_authenticity_token) { 'form-authenticity-token-10032' }
      post :create, format: :json, google_id_token: raw_google_id_token
      expect(response).to have_http_status(:success)
      body_json = JSON.parse response.body
      expect(body_json['form_authenticity_token']).to eql 'form-authenticity-token-10032'
    end
  end
end
