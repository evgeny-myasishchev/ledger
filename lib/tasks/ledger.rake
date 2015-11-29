namespace :ledger do
  desc "Update currencies"
  task :update_currencies => :environment do
    require 'currencies-updater'
    CurrenciesUpdater.update
  end
  
  desc "Update"
  task :update => :environment do
    Rails.application.domain_context.with_projections_initialization
  end
  
  desc "Pull all projections to ensure all commits are handled"
  task :pull_subscriptions => :environment do
    #TODO: Pull projections group only
    Rails.application.event_store_client.pull_subscriptions
  end
  
  task :purge => :environment do
    Rake::Task["ledger:purge_events_and_projections"].invoke
    CurrencyRate.delete_all
    User.delete_all
  end
  
  task :purge_events_and_projections => :environment do
    app = Rails.application
    app.event_store.purge!
    app.event_store_client
      .subscribed_handlers(group: :projections)
      .each { |projection| projection.purge! }
  end
  
  task :rebuild_projections do
    app = init_app_skiping_domain_context
    context = DomainContext.new do |c|
      c.with_database_configs app.config.database_configuration, Rails.env
      c.with_event_bus
      c.with_projections
      c.with_event_store
    end
    context.projections.for_each do |p|
      p.cleanup!
    end
    context.with_projections_initialization
  end
  
  task :discard_snapshots => :environment do
    Snapshot.delete_all
  end
  
  # To be used for mostly for testing purposes.
  desc "Get currency rates for given ledger.aggregate_id"
  task :get_currency_rates, [:aggregate_id] do |t, a|
    raise "Please provide ledger.aggregate_id" unless a.aggregate_id
    ledger = Projections::Ledger.find_by_aggregate_id a.aggregate_id
    user = User.find ledger.owner_user_id
    rates = ledger.get_rates user
    puts "Retrieved rates:"
    rates.each { |rate| 
      puts rate.to_json
    }
  end
end