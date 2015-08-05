namespace :backburner do
  task :environment do
    Rails.application.config.skip_domain_context = true
    Rails.application.config.log_config_path = 'config/backburner-log.xml'
    Rake::Task["environment"].invoke
  end
end