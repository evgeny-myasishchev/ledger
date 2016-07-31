require 'spec_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'google_oauth2' do
    let(:omniauth_auth) { double(:'omniauth.auth') }
    let(:user) { double(:user, persisted?: true) }

    before(:each) do
      request.env['omniauth.auth'] = omniauth_auth
      allow(User).to receive(:from_omniauth) { user }
      allow(controller).to receive(:sign_in_and_redirect) { controller.send(:render, nothing: true) }
    end

    it 'should build and sign-in the user using User.from_omniauth and omniauth data' do
      expect(User).to receive(:from_omniauth).with(omniauth_auth) { user }
      expect(controller).to receive(:sign_in_and_redirect).with(user, event: :authentication) { controller.send(:render, nothing: true) }
      post 'google_oauth2'
    end

    it 'should redirect to new user url saving auth data into the session if failure' do
      expect(user).to receive(:persisted?) { false }
      post 'google_oauth2'
      expect(subject).to redirect_to(new_user_registration_url)
      expect(subject.session['devise.omniauth.auth']).to be_nil
    end
  end
end
