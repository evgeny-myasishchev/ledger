RSpec.configure do |config|
  include Loggable
  config.before(:each) do
    logger.info '======== Starting spec ========'
  end

  config.after(:each) do |example|
    if example.exception.nil?
      logger.info  '======== Spec completed ========'
    else
      logger.error '======== Spec failed ==========='
      logger.error example.exception
    end
  end
end
