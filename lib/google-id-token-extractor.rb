require 'google-id-token'

module GoogleIDToken
  class Extractor
    Validator = GoogleIDToken::Validator.new
    
    def self.extract(token)
      Validator.check(token, ENV['GOAUTH_CLIENT_ID'], ENV['GOAUTH_ANDROID_CLIENT_ID'])
    end
  end
end