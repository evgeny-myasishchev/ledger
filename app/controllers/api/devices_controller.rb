class Api::DevicesController < ApplicationController
  def register
    device_secret = current_user.get_device_secret(params[:device_id])
    device_secret = current_user.add_device_secret(params[:device_id], params[:name]) if device_secret.nil?
    respond_to do |format|
      format.json { render json: {secret: device_secret.secret} }
    end
  end
end
