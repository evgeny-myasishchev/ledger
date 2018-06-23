namespace :users do
  desc 'Register new user'
  task :register, [:email, :currency] => :environment do |_t, a|
    log = Rails.logger
    persistence_factory = Rails.application.persistence_factory
    raise ArgumentError, 'Please provide email' unless a[:email]
    raise ArgumentError, 'Please provide currency' unless a[:currency]

    password = Devise.friendly_token[0, 20]
    log.info "Registering new user: #{a[:email]}, password: #{password}"

    currency = Currency[a[:currency]]
    user = User.create! email: a[:email], password: password

    persistence_factory.begin_unit_of_work({}) do |work|
      work.add_new Domain::Ledger.new.create user.id, user.email, currency
    end
    log.info 'User registered.'
  end
end
