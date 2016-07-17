require 'rails_helper'

RSpec.describe Api::SessionsController, type: :controller do
  describe 'routes', type: :routing do
    it 'routes POST create session' do
      expect(post: 'api/sessions').to route_to controller: 'api/sessions', action: 'create'
    end
  end

  describe 'POST create' do
    let(:dummy_user) { create(:user) }
    let(:raw_google_id_token) { "raw-google-id-token-#{SecureRandom.hex(5)}" }
    let(:valid_aud) { "valid-aud-#{SecureRandom.hex[10]}" }
    let(:aud_whitelist) { Set.new(['aud-1', valid_aud, 'aud-2']) }
    let(:token_data) { { 'email' => dummy_user.email, 'aud' => valid_aud } }
    let(:token) { AccessToken.new token_data }
    let(:dummy_certificates) { [:cert1, :cert2, :cert3] }
    before(:each) do
      allow(AccessToken).to receive(:google_certificates) { dummy_certificates }
      allow(AccessToken).to receive(:extract).with(raw_google_id_token, dummy_certificates) { token }
      allow(Rails.application.config.authentication).to receive(:jwt_aud_whitelist) { aud_whitelist }
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

    describe 'token validation' do
      before(:each) do
        allow(token).to receive(:validate_audience!).and_call_original
      end

      it 'should accept the token if at least one aud is valid' do
        post :create, format: :json, google_id_token: raw_google_id_token
        expect(response).to have_http_status(:success)
        expect(token).to have_received(:validate_audience!).with(aud_whitelist)
      end

      it 'should not accept if token audience is not whitelisted' do
        token_data['aud'] = "invalid-aud-#{SecureRandom.hex[10]}"
        post :create, format: :json, google_id_token: raw_google_id_token
        expect(response).to have_http_status(:unauthorized)
      end
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
