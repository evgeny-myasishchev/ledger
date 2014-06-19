class Projections::Transaction < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  serialize :tag_ids, Set
  
  projection do
    on TransactionReported do |event|
      Transaction.create! account_id: event.aggregate_id,
        transaction_id: event.transaction_id,
        type_id: event.type_id,
        ammount: event.ammount,
        balance: event.balance,
        tag_ids: Set.new(event.tag_ids),
        comment: event.comment,
        date: event.date
    end
  end
end
