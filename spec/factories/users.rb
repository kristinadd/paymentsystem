FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    role { :admin }

    trait :admin do
      role { :admin }
    end

    trait :with_merchant do
      role { :merchant }

      after(:create) do |user|
        create(:merchant, user: user)
      end
    end
  end
end
