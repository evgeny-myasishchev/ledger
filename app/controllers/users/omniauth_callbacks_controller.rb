class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      # Skipping this for now. It can be more than 4kb and if session is in cookie then CookieOverflow is raised
      # session['devise.omniauth.auth'] = request.env['omniauth.auth']
      redirect_to new_user_registration_url
    end
  end
end
