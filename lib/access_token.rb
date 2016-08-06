class AccessToken
  include Loggable

  class TokenError < StandardError
  end

  attr_reader :payload
  def initialize(payload)
    @payload = payload
  end

  def email
    payload['email']
  end

  def validate_audience!(aud)
    aud = [aud] unless aud.respond_to?(:each)
    unless aud.include?(@payload['aud'])
      logger.info "Token audience mismatch. Expected one of: #{aud.to_a.join(', ')}, got: #{@payload['aud']}"
      raise TokenError, 'Invalid audience'
    end
    self
  end

  class << self
    def extract(raw_jwt_token)
      body, header = JWT.decode raw_jwt_token, nil, false
      cert = Certificates.get_certificate body, header
      begin
        decoded_token = JWT.decode raw_jwt_token, cert.public_key
      rescue JWT::VerificationError => e
        logger.info "Failed to decode token: #{e.inspect}"
        raise TokenError, 'Failed to decode token'
      end
      new decoded_token[0]
    end
  end
end
