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
end