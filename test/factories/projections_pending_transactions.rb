FactoryGirl.define do
  factory :projections_pending_transaction, :class => 'Projections::PendingTransaction' do
    transaction_id { SecureRandom.uuid }
    amount "#{SecureRandom.random_number(5000)}.#{SecureRandom.random_number(99).to_s.ljust(2, '0')}"
    association :user, factory: :user
    comment { FFaker::Lorem.phrase }
    type_id Domain::Transaction::ExpenseTypeId
  end
end
