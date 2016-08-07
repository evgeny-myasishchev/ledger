class AccessToken::Certificates
  class << self
    def providers
      @providers || begin
        providers = Hash.new do |_hash, key|
          raise AccessToken::TokenError, "Unknown issuer: #{key}"
        end
        google_provider = GoogleProvider.new
        providers['https://accounts.google.com'] = google_provider
        providers['accounts.google.com'] = google_provider
        providers.freeze
      end
    end

    def get_certificate(jwt_body, jwt_header)
      providers[jwt_body['iss']].get_certificate jwt_header
    end
  end

  class BaseProvider
    def get_certificate(_jwt_header)
      raise 'Not implemented'
    end
  end

  class GoogleProvider < BaseProvider
    include Loggable
    GOOGLE_CERTS_URI = 'https://www.googleapis.com/oauth2/v1/certs'.freeze

    attr_reader :cache

    def initialize(initial_certificates = {}, verbose: false)
      @cache = create_cache
      @cache.merge! initial_certificates
      @verbose = verbose
    end

    def get_certificate(jwt_header)
      kid = jwt_header['kid']
      unless cache.key?(kid)
        # TODO: Multithreading may be an issue here. Investigation is required
        logger.debug "Certificate for kid: #{kid} not found. Refreshing from google api..."
        certs_before = cache.length
        fetched_certs = fetch_certificates
        cache.merge! fetched_certs
        fetched_count = cache.length - certs_before
        logger.debug "Fetched #{fetched_certs.length} certificates. #{fetched_count} of them are new."
        log_fetched_certs fetched_certs
        remove_expired_certificates_from_cache cache
      end

      cache[kid]
    end

    private

    def create_cache
      Hash.new do |_hash, key|
        logger.info "Certificate with kid=#{key} not found"
        raise AccessToken::TokenError, "Certificate with kid=#{key} not found"
      end
    end

    def fetch_certificates
      uri = URI(GOOGLE_CERTS_URI)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(Net::HTTP::Get.new(uri.request_uri))
      raise "Failed to get certificates: #{res.code} - #{res.message}" unless res.is_a?(Net::HTTPSuccess)
      logger.debug("Got response: #{res.body}") if @verbose
      Hash[MultiJson.load(res.body).map do |key, cert|
             [key, OpenSSL::X509::Certificate.new(cert)]
           end]
    end

    def remove_expired_certificates_from_cache(cache)
      cache.delete_if do |kid|
        cert = cache[kid]
        if cert.not_after <= Time.now
          logger.debug "Removing expired certificate from cache. Kid=#{kid}, subject: #{cert.subject}, not_after: #{cert.not_after}"
          true
        end
      end
    end

    def log_fetched_certs(fetched_certs)
      fetched_certs.each do |new_kid, new_cert|
        logger.debug "- kid: #{new_kid}, subject: #{new_cert.subject}, not_after: #{new_cert.not_after.iso8601}"
      end
    end
  end
end
