class Api::DevicesController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: current_user.device_secrets }
    end
  end

  def register
    device_secret = current_user.get_device_secret(params[:device_id])
    device_secret = current_user.add_device_secret(params[:device_id], params[:name]) if device_secret.nil?
    respond_to do |format|
      format.json { render json: {secret: device_secret.secret} }
    end
  end
  
  def reset_secret_key
    current_user.reset_device_secret(params[:id])
    render nothing: true
  end


  def destroy
    current_user.remove_device_secret(params[:id])
    render nothing: true
  end
end
