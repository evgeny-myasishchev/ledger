Rails.application.configure do |app|
  jwt_accepted_aud = []
  jwt_accepted_aud << ENV['GOAUTH_CLIENT_ID'] if ENV.key?('GOAUTH_CLIENT_ID')
  jwt_accepted_aud << ENV['JWT_ACCEPTED_AUD'].split(',') if ENV.key?('JWT_ACCEPTED_AUD')
  app.config.authentication.jwt_accepted_aud = jwt_accepted_aud
end
