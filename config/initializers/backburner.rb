# Backburner initialization
# Configuration environment:
# * BEANSTALKD_URL - Sample: beanstalk://127.0.0.1
# * BACKBURNER_TUBE_NS - Sample: development.my-ledger.com

class BackburnerWorker < Backburner::Workers::Simple
  def start(*args)
    log_info 'Pulling subscriptions on start...'
    Rails.application.event_store_client.pull_subscriptions
    super
  end
end

Backburner.configure do |config|
  config.beanstalk_url    = [ENV.fetch('BEANSTALKD_URL', 'beanstalk://127.0.0.1:11321')]
  config.tube_namespace   = ENV.fetch('BACKBURNER_TUBE_NS', 'development.my-ledger.com')
  config.on_error         = ->(e) { puts e }
  config.max_job_retries  = 3 # default 0 retries
  config.retry_delay      = 2 # default 5 seconds
  config.default_priority = 65_536
  config.respond_timeout  = 120
  config.default_worker   = BackburnerWorker
  config.logger           = Log4r::Logger.new('Ledger::Backburner')
  config.primary_queue    = 'default'
  config.priority_labels  = { custom: 50, useless: 1000 }
  config.reserve_timeout  = nil
end

Backburner.default_queues << 'default'
Backburner.default_queues << 'mailers'

ActiveJob::Base.queue_adapter = :backburner
Rails.application.config.active_job.queue_adapter = :backburner
