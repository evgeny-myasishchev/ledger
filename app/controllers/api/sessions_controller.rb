require 'google-id-token-extractor'

class Api::SessionsController < ApplicationController
  
  skip_filter :authenticate_user!
  protect_from_forgery except: :create
  
  def create
    if params[:google_id_token]
      begin
        token = GoogleIDToken::Extractor.extract(params[:google_id_token])
        user = User.find_by email: token['email']
        if user
          sign_in :user, user
        else
          logger.debug "Authentication failed. User #{token['email']} not found."
        end
      rescue GoogleIDToken::InvalidTokenException => e
        logger.error 'Failed to extract the google_id_token'
        logger.error $!.inspect
      end
    end
    respond_to do |format|
      format.json {
        if user_signed_in?
          render json: {form_authenticity_token: form_authenticity_token}
        else
          render nothing: true, status: :unauthorized
        end
      }
    end
  end
end
