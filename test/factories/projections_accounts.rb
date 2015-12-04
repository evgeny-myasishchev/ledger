FactoryGirl.define do
  factory :projections_account, :class => 'Projections::Account' do
    ledger_id { 'ledger-1' }
    aggregate_id { SecureRandom.uuid }
    sequence(:sequential_number) { |n| n }
    owner_user_id { 0 }
    authorized_user_ids { '' }
    currency_code { 'UAH' }
    name { "account-#{SecureRandom.hex(5)}" }
    balance { 0 }
    is_closed { false }
  end
end
