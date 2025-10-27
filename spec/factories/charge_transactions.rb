FactoryBot.define do
  factory :charge_transaction do
    association :merchant
    amount { Faker::Commerce.price(range: 1.0..1000.0) }
    status { :approved }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }

    transient do
      create_authorize { true }
    end

    after(:build) do |charge, evaluator|
      if evaluator.create_authorize && charge.referenced_transaction.nil?
        auth_amount = charge.amount || 100.0
        charge.referenced_transaction = create(
          :authorize_transaction,
          merchant: charge.merchant,
          amount: auth_amount,
          status: :approved
        )
        charge.amount = auth_amount if charge.amount.nil?
      end
    end

    trait :with_error_authorize do
      after(:build) do |charge|
        auth_amount = charge.amount || 100.0
        charge.referenced_transaction = create(
          :authorize_transaction,
          merchant: charge.merchant,
          amount: auth_amount,
          status: :error
        )
        charge.amount = auth_amount if charge.amount.nil?
      end
    end

    trait :with_error_status do
      status { :error }
    end
  end
end
