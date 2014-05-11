require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ledger
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.autoload_paths += %W(#{config.root}/lib)
    
    config.log_config_path = File.join(config.root, 'config', 'log.xml') unless config.respond_to?(:log_config_path)
    
    initializer :initialize_log4r, {:before => :initialize_logger} do
      LogFactory.configure(log_file_path: config.paths['log'].first, app_root: config.root, config_file: config.log_config_path)
      config.logger = LogFactory.logger "ledger"
      CommonDomain::Logger.factory = CommonDomain::Logger::Log4rFactory.new
    end
    
    attr_reader :domain_context
    initializer :initialize_services do |app|
      @domain_context = DomainContext.new do |c|
        c.with_database_configs app.config.database_configuration, Rails.env
        c.with_projections
        c.with_event_store
        c.with_projections_initialization
        c.with_services
        c.with_command_handlers
        c.with_dispatch_undispatched_commits
      end
    end unless Rails.env.test?
  end
end
