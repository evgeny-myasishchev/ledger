require 'log4r'
require 'log4r/configurator'
require 'log4r/outputter/emailoutputter'

class LogFactory
  def self.root_logger
    @root_logger || 'Ledger'
  end
  
  def self.logger(name)
    CommonDomain::Logger.get(name)
  end
  
  def self.logger_for_class(klass)
    logger "#{root_logger}::#{klass}"
  end
  
  def self.configure(config)
    #It might be used even if there is no Rails.root
    options = {
      root_logger: 'Ledger',
      log_file_path: config.paths['log'].first,
      app_root: config.root,
      config_file: config.log_config_path
    }
    @root_logger = options[:root_logger]
    Log4r::Configurator['log_file_path'] = options[:log_file_path]
    config_file = options[:config_file] || File.join(options[:app_root], "config", "log.xml")
    Log4r::Configurator.load_xml_file(config_file)

    CommonDomain::Logger.factory = CommonDomain::Logger::Log4rFactory.new
    ActiveRecord::Base.logger = LogFactory.logger 'ActiveRecord'

    config.logger = LogFactory.logger @root_logger
  end
end