namespace :ledger do
  desc "Seed dummy data"
  task :dummy_seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'dummy-seeds.rb')
    load(seed_file)
  end
  
  desc "Update currencies"
  task :update_currencies => :environment do
    require 'currencies-updater'
    CurrenciesUpdater.update
  end
  
  desc "Update"
  task :update => :environment do
    Rails.application.domain_context.with_projections_initialization
  end
  
  desc "Dispatch undispatched commits"
  task :dispatch_undispatched_commits do
    app = init_app_skiping_domain_context
    DomainContext.new do |c|
      c.with_database_configs app.config.database_configuration, Rails.env
      c.with_event_bus
      c.with_projections
      c.with_event_store
      c.with_dispatch_undispatched_commits
    end
  end
  
  desc "Purge events and projections"
  task :purge_events_and_projections do
    app = init_app_skiping_domain_context
    context = DomainContext.new do |c|
      c.with_database_configs app.config.database_configuration, Rails.env
      c.with_event_bus
      c.with_projections
      c.with_event_store
    end
    context.event_store.purge
    context.projections.for_each do |p|
      p.cleanup!
    end
  end
  
  def init_app_skiping_domain_context
    app = Rails.application
    app.skip_domain_context = true
    app.initialize!
    app
  end
end