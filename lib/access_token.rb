class AccessToken
  include Loggable

  GOOGLE_CERTS_URI = 'https://www.googleapis.com/oauth2/v1/certs'.freeze

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
    def extract(raw_jwt_token, certificates)
      decoded_token = nil
      last_index = certificates.length - 1
      certificates.each_with_index do |cert, index|
        begin
          decoded_token = JWT.decode raw_jwt_token, cert.public_key
          break
        rescue JWT::VerificationError
          raise TokenError, 'Failed to decode token with provided certificates' if index >= last_index
        end
      end
      new decoded_token[0]
    end

    def google_certificates
      # TODO: They should be expiring. Needs to be investigated
      # This should be converted to providers some day
      @google_certificates ||= begin
        uri = URI(GOOGLE_CERTS_URI)
        logger.debug "Fetching google certificates from #{GOOGLE_CERTS_URI}"
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        res = http.request(Net::HTTP::Get.new(uri.request_uri))
        raise "Failed to get certificates: #{res.code} - #{res.message}" unless res.is_a?(Net::HTTPSuccess)
        new_certs = MultiJson.load(res.body)
        new_certs.map { |_k, v| OpenSSL::X509::Certificate.new(v) }
      end
    end

    def forget_google_certificates
      @google_certificates = nil
    end
  end
end
