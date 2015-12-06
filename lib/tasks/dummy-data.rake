namespace :ledger do
  desc "Seed dummy data"
  task :dummy_seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'dummy-seeds.rb')
    load(seed_file)
  end

  desc "Generate dummy pending transactions"
  task :dummy_pending_transactions, [:user_id, :number] => :environment do |_, a|
    log = Rails.logger
    user = ensure_user!(a)
    log.info "Generating dummy pending transactions for user: #{user.inspect}"

    generator = Dev::DummyPendingTransactionsGenerator.new user, Rails.application
    generator.generate a.number.try(:to_i) || 10
    print_and_getc('Transactions generated.')
  end

  desc 'Report pending transaction'
  task :report_pending_transaction, [:user_id, :account_id, :amount, :comment, :type_id] => :environment do |_, a|
    log = Rails.logger
    user = ensure_user!(a)
    log.info "Reporting pending transactions for user: #{user.inspect}"

    generator = Dev::DummyPendingTransactionsGenerator.new user, Rails.application
    generator.report_pending_transaction(account_id: a.account_id, amount: a.amount, comment: a.comment, type_id: a.type_id)
    print_and_getc('Transaction reported.')
  end

  private

  def ensure_user!(a)
    if a[:user_id].nil? || a[:user_id].blank? || (user = User.find(a[:user_id])).nil?
      puts "Available users:"
      User.all.each { |u|
        puts u.inspect
      }
      raise 'Please provide valid user_id'
    end
    user
  end

  def print_and_getc(msg)
    print msg
    print 'Press any key in few seconds (to make sure subscriptions are pulled)'
    STDIN.getc
  end
end