namespace :ledger do
  desc 'Update currencies'
  task :update_currencies => :environment do
    require 'currencies-updater'
    CurrenciesUpdater.update
  end

  desc 'Pull all subscriptions to ensure all commits are handled'
  task :pull_subscriptions => :environment do
    Rails.application.event_store_client.pull_subscriptions
    puts 'Please make sure all subscriptions have finished pulling and press any Ctrl+C.'
    STDIN.getc
  end

  task :purge => :environment do
    Rake::Task['ledger:purge_events'].invoke
    Rake::Task['ledger:purge_projections'].invoke
    CurrencyRate.delete_all
    User.delete_all
  end

  task :purge_events => :environment do
    app = Rails.application
    app.event_store.purge!
  end

  task :purge_projections => :environment do
    app = Rails.application
    app.event_store_client
        .subscriptions(group: :projections)
        .each do |subscription|
      subscription.handlers.map(&:purge!)
      Checkpoint.where(identifier: subscription.identifier).delete_all
    end
  end

  desc 'Purge projection for given identifier'
  task :purge_projection, [:identifier] => :environment do |_, a|
    unless a.identifier
      STDERR.puts 'Please provide identifier. Possible identifiers are:'
      Checkpoint.all.each { |c| puts c.identifier }
      exit(1)
    end
    identifier = a.identifier
    Checkpoint.where(identifier: identifier).delete_all
    app = Rails.application
    app.event_store_client
        .subscriptions(group: :projections)
        .select { |s| s.identifier == identifier }
        .each do |subscription|
      subscription.handlers.map(&:purge!)
    end
  end

  task :discard_snapshots => :environment do
    Snapshot.delete_all
  end

  # To be used for mostly for testing purposes.
  desc 'Get currency rates for given ledger.aggregate_id'
  task :get_currency_rates, [:aggregate_id] do |t, a|
    raise 'Please provide ledger.aggregate_id' unless a.aggregate_id
    ledger = Projections::Ledger.find_by_aggregate_id a.aggregate_id
    user = User.find ledger.owner_user_id
    rates = ledger.get_rates user
    puts 'Retrieved rates:'
    rates.each { |rate|
      puts rate.to_json
    }
  end
end