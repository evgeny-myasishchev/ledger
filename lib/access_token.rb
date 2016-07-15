class AccessToken
  include Loggable

  GOOGLE_CERTS_URI = 'https://www.googleapis.com/oauth2/v1/certs'.freeze

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

    def google_certificates
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
