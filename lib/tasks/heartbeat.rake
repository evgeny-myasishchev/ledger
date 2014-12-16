namespace :hb do
  task :issue_logs do
    # This task is good to test various outputters (like email)
    require File.join(Rails.root, 'lib', 'log_factory')
    require 'log4r/outputter/emailoutputter'
    trouble = Log4r::Logger.new('log4r')
    trouble.add Log4r::Outputter.stdout
    
    Rails.application.initialize_logging
    logger = Rails.application.config.logger
    logger.debug 'This is a test debug log. '
    logger.info 'This is a test info log. '
    logger.warn 'This is a test warn log. '
    logger.error 'This is a test error log.'
    logger.fatal 'This is a test fatal log.'
  end
end