class Domain::PendingTransaction < CommonDomain::Aggregate
  include Loggable
  include CommonDomain::Infrastructure
  include Domain::Events
  
  attr_reader :transaction_id, :amount, :date, :tag_ids, :comment, :account_id
  
  def report user, transaction_id, amount, date: nil, tag_ids: nil, comment: nil, account_id: nil
  end
  
  def adjust amount: nil, date: nil, tag_ids: nil, comment: nil, account_id: nil
  end
  
  def approve account
  end
end