require 'google-id-token-extractor'

class Api::SessionsController < ApplicationController
  
  skip_filter :authenticate_user!
  protect_from_forgery except: :create
  
  def create
    if params[:google_id_token]
      token = GoogleIDToken::Extractor.extract(params[:google_id_token])
      user = User.find_by email: token['email']
      sign_in :user, user if user
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
