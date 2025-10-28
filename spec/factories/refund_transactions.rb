FactoryBot.define do
  factory :refund_transaction do
    association :merchant
    amount { Faker::Commerce.price(range: 1.0..1000.0) }
    status { :approved }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }

    transient do
      create_charge { true }
    end

    after(:build) do |refund, evaluator|
      # Ensure merchant is persisted before creating related transactions
      unless refund.merchant.persisted?
        refund.merchant.user&.save!(validate: false)
        refund.merchant.save!
      end

      if evaluator.create_charge && refund.referenced_transaction.nil?
        # Create the full chain: Authorize → Charge
        authorize = create(
          :authorize_transaction,
          merchant: refund.merchant,
          amount: refund.amount || 100.0,
          status: :approved
        )

        charge = create(
          :charge_transaction,
          merchant: refund.merchant,
          referenced_transaction: authorize,
          amount: refund.amount || 100.0,
          status: :approved
        )

        refund.referenced_transaction = charge
        refund.amount = charge.amount if refund.amount.nil?
      end
    end

    trait :with_error_charge do
      after(:build) do |refund|
        unless refund.merchant.persisted?
          refund.merchant.user&.save!(validate: false)
          refund.merchant.save!
        end

        authorize = create(
          :authorize_transaction,
          merchant: refund.merchant,
          amount: refund.amount || 100.0,
          status: :approved
        )

        charge = create(
          :charge_transaction,
          merchant: refund.merchant,
          referenced_transaction: authorize,
          amount: refund.amount || 100.0,
          status: :error
        )

        refund.referenced_transaction = charge
        refund.amount = charge.amount if refund.amount.nil?
      end
    end

    trait :with_error_status do
      status { :error }
    end
  end
end
