FactoryGirl.define do
  factory :user do
    email { FFaker::InternetSE.email(FFaker::InternetSE.user_name) }
    after(:build) { |u| u.password_confirmation = u.password = FFaker::Internet.password }
  end
end
