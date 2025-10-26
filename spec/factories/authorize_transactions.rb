FactoryBot.define do
  factory :authorize_transaction do
    association :merchant
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    status { :approved }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }

    trait :reversed do
      status { :reversed }
    end
  end
end
