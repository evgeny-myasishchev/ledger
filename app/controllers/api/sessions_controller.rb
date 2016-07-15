require 'google_id_token_extractor'

class Api::SessionsController < ApplicationController
  skip_filter :authenticate_user!
  protect_from_forgery except: :create

  def create
    sign_in_with_token params[:google_id_token] if params[:google_id_token]
    respond_to do |format|
      format.json do
        if user_signed_in?
          render json: { form_authenticity_token: form_authenticity_token }
        else
          render nothing: true, status: :unauthorized
        end
      end
    end
  end

  private

  def sign_in_with_token(raw_token)
    token = AccessToken.extract(raw_token, AccessToken.google_certificates)
    user = User.find_by email: token['email']
    if user
      logger.info "User found (id='#{user.id}', email='#{token['email']}'). Authenticating..."
      sign_in :user, user
    else
      logger.info "Authentication failed. User #{token['email']} not found."
    end
  rescue AccessToken::TokenError => e
    logger.warn "Failed to extract the google_id_token: #{e.inspect}"
  end
end
