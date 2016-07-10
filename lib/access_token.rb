class AccessToken
  class TokenError < StandardError
  end

  attr_reader :payload
  def initialize(payload)
    @payload = payload
  end

  def validate_audience!(aud)
    aud = [aud] unless aud.respond_to?(:each)
    raise TokenError, 'Invalid audience' unless aud.detect { |a| @payload['aud'] == a }
    self
  end

  class << self
    def extract(raw_jwt_token, certificates)
      decoded_token = nil
      certificates.each do |cert|
        begin
          decoded_token = JWT.decode raw_jwt_token, cert.public_key
        rescue JWT::VerificationError
          raise TokenError, 'Failed to decode token with provided certificates' if certificates.last == cert
        end
      end
      new decoded_token[0]
    end
  end
end
