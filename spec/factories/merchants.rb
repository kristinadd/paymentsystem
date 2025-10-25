FactoryBot.define do
  factory :merchant do
    sequence(:name) { |n| "Merchant #{n}" }
    sequence(:email) { |n| "merchant#{n}@example.com" }

    description { "A test merchant for processing payments" }
    active { true }
    total_transaction_sum { 0 }

    trait :inactive do
      active { false }
    end
  end
end
