require 'log4r'
require 'log4r/configurator'

class LogFactory
  def self.logger(name)
    Log4r::Logger[name] || Log4r::Logger.new(name)
  end
  
  def self.configure(options = {})
    #It might be used even if there is no Rails.root
    options = {
      log_file_path: File.expand_path('../../log/application.log', __FILE__),
      app_root: File.expand_path('../..', __FILE__),
      config_file: nil
    }.merge! options
    Log4r::Configurator['log_file_path'] = options[:log_file_path]
    config_file = options[:config_file] || File.join(options[:app_root], "config", "log.xml")
    Log4r::Configurator.load_xml_file(config_file)
  end
end