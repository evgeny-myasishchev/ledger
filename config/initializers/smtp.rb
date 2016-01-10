# Backburner initialization 
# Configuration environment:
# * SMTP_HOST
# * SMTP_PORT
# * SMTP_DOMAIN
# * SMTP_USER_NAME
# * SMTP_PASSWORD
# * SMTP_AUTHENTICATION
# * SMTP_ENABLE_STARTTLS_AUTO

if ENV['SMTP_HOST'].present?
  ActionMailer::Base.delivery_method = :smtp
  
  ActionMailer::Base.smtp_settings = {
    address: ENV['SMTP_HOST'],
    port: ENV.fetch('SMTP_PORT', 587).to_i,
    domain: ENV.fetch('SMTP_DOMAIN', 'localhost'),
    user_name: ENV['SMTP_USER_NAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
    enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'].present?
  }
end