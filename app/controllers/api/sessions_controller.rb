require 'google_id_token_extractor'

class Api::SessionsController < ApplicationController
  skip_filter :authenticate_user!
  protect_from_forgery except: :create

  def create
    result = sign_in_with_token params[:google_id_token]
    respond_to do |format|
      format.json do
        if user_signed_in?
          render json: { form_authenticity_token: form_authenticity_token }
        else
          render status: result[:http_status], json: { error: { code: result[:error_code] } }
        end
      end
    end
  end

  private

  def sign_in_with_token(raw_token)
    result = { http_status: :unauthorized, error_code: 'invalid-token' }
    begin
      token = AccessToken
              .extract(raw_token, AccessToken.google_certificates)
              .validate_audience!(Rails.application.config.authentication.jwt_aud_whitelist)
      user = User.find_by email: token.email
      if user
        logger.info "User found (id='#{user.id}', email='#{token.email}'). Authenticating..."
        sign_in :user, user
        result = nil
      else
        logger.info "Authentication failed. User #{token.email} not found."
      end
    rescue AccessToken::TokenError => e
      logger.error "Failed to extract the google_id_token: #{e.inspect}"
    rescue JWT::ExpiredSignature => e
      logger.info %(The signature of the token has expired: #{e.inspect})
      result[:error_code] = 'token-expired'
    end if raw_token
    result
  end
end
