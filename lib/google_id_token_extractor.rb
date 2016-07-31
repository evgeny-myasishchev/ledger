require 'google_id_token'

module GoogleIDToken
  class InvalidTokenException < StandardError
  end

  class Extractor
    def self.extract(token, env = ENV)
      validator = Validator.new
      decoded_hash = validator.check(token, env['GOAUTH_CLIENT_ID'], env['GOAUTH_SENDER_CLIENT_ID'])
      raise InvalidTokenException, validator.problem if decoded_hash.nil?
      decoded_hash
    end
  end
end
