namespace :ledger do
  desc "Seed dummy data"
  task :dummy_seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'dummy-seeds.rb')
    load(seed_file)
  end
  
  desc "Generate dummy pending transactions"
  task :dummy_pending_transactions, [:user_id] => :environment do |t, a|
    log = Rails.logger
    if a[:user_id].nil? || a[:user_id].blank? || (user = User.find(a[:user_id])).nil?
      puts "Available users:"
      User.all.each { |u| 
        puts u.inspect
      }
      raise 'Please provide valid user_id'
    end
    log.info "Generating dummy pending transactions for user: #{user.inspect}"
    
    generator = Dev::DummyPendingTransactionsGenerator.new user, Rails.application.domain_context
    generator.generate 10
  end
end