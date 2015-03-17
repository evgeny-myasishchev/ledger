require 'google-id-token'

module GoogleIDToken
  Validator = GoogleIDToken::Validator.new
  
  def extract(token)
    Validator.check(token, ENV['GOAUTH_CLIENT_ID'], ENV['GOAUTH_ANDROID_CLIENT_ID'])
  end
end