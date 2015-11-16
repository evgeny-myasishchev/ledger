namespace :users do
  desc "Register new user"
  task :register, [:email, :currency] => :environment do |t, a|
    log = Rails.logger
    context = Rails.application.domain_context
    raise ArgumentError.new 'Please provide email' unless a[:email]
    raise ArgumentError.new 'Please provide currency' unless a[:currency]
    log.info "Registering new user: #{a[:email]}"
    
    currency = Currency[a[:currency]]
    user = User.create! email: a[:email], password: Devise.friendly_token[0,20]

    ledger = Domain::Ledger.new.create user.id, user.email, currency

    repo = context.repository_factory.create_repository
    repo.save ledger
    log.info "User registered."
  end
end