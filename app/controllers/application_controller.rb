class ApplicationController < ActionController::Base
  include CommonDomain::DispatchCommand
  dispatch_with_controller_context user_id: lambda { |controller| controller.current_user.id }
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :authenticate_user!
end
