namespace :ledger do
  desc "Seed dummy data"
  task :dummy_seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'dummy-seeds.rb')
    load(seed_file)
  end
end