class Projections::Ledger < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  serialize :shared_with_user_ids, Set

  def authorized_user_ids
    @authorized_user_ids ||= begin
      authorized_user_ids = shared_with_user_ids.to_a
      authorized_user_ids << owner_user_id
      authorized_user_ids
    end    
  end
  
  def ensure_authorized! user
    unless authorized_user_ids.include?(user.id)
      raise Errors::AuthorizationFailedError.new "The user(id=#{user.id}) is not authorized on ledger(aggregate_id=#{aggregate_id})."
    end
  end
  
  def self.get_user_ledgers(user)
    where(owner_user_id: user.id).select(:id, :aggregate_id, :name).to_a
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
      Ledger.create!(aggregate_id: event.aggregate_id, owner_user_id: event.user_id, name: event.name, currency_code: event.currency_code) unless
        Ledger.exists?(aggregate_id: event.aggregate_id)
    end
    
    on LedgerRenamed do |event|
      Ledger.where(aggregate_id: event.aggregate_id).update_all name: event.name
    end
    
    on LedgerShared do |event|
      ledger = Ledger.find_by_aggregate_id event.aggregate_id
      ledger.shared_with_user_ids.add event.user_id
      ledger.save!
    end
  end
end
