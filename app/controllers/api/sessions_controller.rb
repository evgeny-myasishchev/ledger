class Api::SessionsController < ApplicationController
  
  skip_filter :authenticate_user!
  
  def new
    respond_to do |format|
      format.json {
        render json: {form_authenticity_token: form_authenticity_token}
      }
    end
  end
end
