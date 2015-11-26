require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'dotenv'
Dotenv.load

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

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    self.paths['config/database'] = ENV['DB_CONFIG'] if ENV.key?('DB_CONFIG')
    
    config.autoload_paths += %W(#{config.root}/lib)
    
    config.log_config_path = ENV['LOG_CONFIG'] || File.join(config.root, 'config', 'log.xml') unless config.respond_to?(:log_config_path)
    
    config.assets.paths << Rails.root.join("vendor", "assets", "bootstrap")
    config.assets.paths << Rails.root.join("vendor", "assets", "bootstrap", "fonts")
    config.assets.precompile += %w( *.eot *.svg *.ttf *.woff *.woff2 )
    
    initializer :initialize_log4r, {:before => :initialize_logger} do
      initialize_logging
    end
    
    config.skip_domain_context = false

    # TODO: Move to individual initializers and remove
    # attr_reader :domain_context
    # initializer :initialize_domain_context do |app|
    #   @domain_context = DomainContext.new do |c|
    #     c.with_database_configs app.config.database_configuration, Rails.env
    #     c.with_event_bus
    #     c.with_projections
    #     c.with_event_store
    #     c.with_snapshots Snapshot
    #     c.with_services
    #     c.with_command_handlers
    #     c.with_command_dispatch_middleware
    #     c.with_dispatch_undispatched_commits
    #   end unless config.skip_domain_context
    # end unless Rails.env.test?
    
    attr_accessor :currencies_store
    config.before_initialize { |app| app.currencies_store = {} }
    
    def initialize_logging
      LogFactory.configure(log_file_path: config.paths['log'].first, app_root: config.root, config_file: config.log_config_path)
      config.logger = LogFactory.logger "ledger"
      CommonDomain::Logger.factory = CommonDomain::Logger::Log4rFactory.new
    end
  end
end
