FactoryBot.define do
  factory :authorize_transaction do
    association :merchant
    amount { Faker::Commerce.price(range: 1.0..1000.0) }
    status { :approved }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }

    trait :reversed do
      status { :reversed }
    end
  end
end
