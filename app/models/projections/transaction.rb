class Projections::Transaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  def add_tag(the_id)
    wrapped_tag_id = "{#{the_id}}"
    if !self.tag_ids.nil? && self.tag_ids.include?(wrapped_tag_id)
      return
    end
    result = self.tag_ids || ""
    result << ',' unless result.blank?
    result << wrapped_tag_id
    self.tag_ids = result
  end
  
  def self.get_account_transactions(user, account_id)
    account = Account.ensure_authorized! account_id, user
    Transaction.
      where('account_id = :account_id', account_id: account.aggregate_id).
      select(:id, :transaction_id, :type_id, :ammount, :balance, :tag_ids, :comment, :date)
  end
  
  projection do
    on TransactionReported do |event|
      t = Transaction.new account_id: event.aggregate_id,
        transaction_id: event.transaction_id,
        type_id: event.type_id,
        ammount: event.ammount,
        balance: event.balance,
        comment: event.comment,
        date: event.date
      event.tag_ids.each { |tag_id| t.add_tag tag_id }
      t.save!
    end
  end
end
