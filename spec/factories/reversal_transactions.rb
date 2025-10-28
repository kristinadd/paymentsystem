FactoryBot.define do
  factory :reversal_transaction do
    association :merchant
    amount { nil }
    status { :approved }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }

    transient do
      create_authorize { true }
    end

    after(:build) do |reversal, evaluator|
      # Ensure merchant is persisted before creating related transactions
      unless reversal.merchant.persisted?
        reversal.merchant.user&.save!(validate: false)
        reversal.merchant.save!
      end

      if evaluator.create_authorize && reversal.referenced_transaction.nil?
        reversal.referenced_transaction = create(
          :authorize_transaction,
          merchant: reversal.merchant,
          amount: 100.0,
          status: :approved
        )
      end
    end

    trait :with_charged_authorize do
      after(:build) do |reversal|
        unless reversal.merchant.persisted?
          reversal.merchant.user&.save!(validate: false)
          reversal.merchant.save!
        end

        authorize = create(
          :authorize_transaction,
          merchant: reversal.merchant,
          amount: 100.0,
          status: :approved
        )

        # Create a charge for this authorize
        create(
          :charge_transaction,
          merchant: reversal.merchant,
          referenced_transaction: authorize,
          amount: 100.0
        )

        reversal.referenced_transaction = authorize
      end
    end

    trait :with_error_status do
      status { :error }
    end
  end
end
