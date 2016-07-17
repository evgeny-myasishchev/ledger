Rails.application.configure do |app|
  jwt_aud_whitelist = Set.new
  jwt_aud_whitelist << ENV['GOAUTH_CLIENT_ID'] if ENV.key?('GOAUTH_CLIENT_ID')
  jwt_aud_whitelist << ENV['JWT_AUD_WHITELIST'].split(',') if ENV.key?('JWT_AUD_WHITELIST')
  app.config.authentication.jwt_aud_whitelist = jwt_aud_whitelist
end
