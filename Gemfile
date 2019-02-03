source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4'

# Use postgres as the database for Active Record
gem 'pg'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# Use jquery as the JavaScript library
gem 'jquery-rails'

gem 'angularjs-rails'

gem 'angular-rails-templates'
gem 'sprockets', '< 3' # For angular rails templates it should be not more than 2

gem 'momentjs-rails', '~> 2.5.0'
gem 'bootstrap3-datetimepicker-rails', '~> 3.0.0'

# Handle authentication with devise
gem 'devise'
gem 'omniauth-google-oauth2', '~> 0.6.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use debugger
# gem 'debugger', group: [:development, :test]

# Handling concurrency with concurrent gem
gem 'concurrent-ruby'
gem 'concurrent-ruby-ext'

gem 'event-store', github: 'evgeny-myasishchev/event-store'
gem 'common-domain', github: 'evgeny-myasishchev/common-domain'

# Log with log4r
gem 'log4r', github: 'colbygk/log4r'

# Use backburner (beanstalkd) to run active jobs on production
gem 'backburner'

gem 'dotenv-rails' # Store ENV in .env

gem 'jwt', '~> 2.0'

group :development, :test do
  # Use Capistrano for deployment
  gem 'capistrano'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'

  gem 'web-console', '~> 2.0'
  gem 'responders', '~> 2.0'

  # Using foreman to run app processes in dev
  gem 'foreman'

  gem 'rspec-core', '>= 3.0'
  gem 'rspec-rails', '>= 3.0'
  gem 'puma'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'jasmine-rails'
  gem 'rest-client'

  gem 'factory_girl_rails'
  gem 'ffaker'

  gem 'rubocop', require: false

  gem 'webmock'

  gem 'guard-rspec', require: false
end

group :production do
  # Use passenger as an application server
  gem 'passenger'
end
