class Projections::Ledger < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include Projections::UserAuthorizable
  
  def ensure_authorized! user
    unless authorized_user_ids.include?("{#{user.id}}")
      raise Errors::AuthorizationFailedError.new "The user(id=#{user.id}) is not authorized on ledger(aggregate_id=#{aggregate_id})."
    end
  end
  
  def self.get_user_ledgers(user)
    where('authorized_user_ids LIKE ?', "%{#{user.id}}%").select(:id, :aggregate_id, :name, :currency_code).to_a
  end
  
  def self.get_rates user, ledger_id
    ledger = find_by_aggregate_id ledger_id
    ledger.get_rates user
  end
  
  def get_rates user
    ensure_authorized! user
    currency_codes = Account.select(:currency_code).
      where('ledger_id = ? AND authorized_user_ids LIKE ? AND NOT currency_code = ?', aggregate_id, "%{#{user.id}}%", currency_code).
      distinct.
      map { |a| a.currency_code }
    CurrencyRate.get from: currency_codes, to: currency_code
  end
  
  projection do
    on LedgerCreated do |event|
      Ledger.create!(aggregate_id: event.aggregate_id, authorized_user_ids: "{#{event.user_id}}", owner_user_id: event.user_id, name: event.name, currency_code: event.currency_code) unless
        Ledger.exists?(aggregate_id: event.aggregate_id)
    end
    
    on LedgerRenamed do |event|
      Ledger.where(aggregate_id: event.aggregate_id).update_all name: event.name
    end
    
    on LedgerShared do |event|
      Ledger.where(aggregate_id: event.aggregate_id).each { |l|
        l.authorize_user event.user_id
        l.save!
      }
    end
  end
end
