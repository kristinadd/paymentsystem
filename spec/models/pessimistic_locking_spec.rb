require 'rails_helper'

RSpec.describe "Pessimistic Locking", type: :model do
  it "prevents race condition between concurrent charge and reversal" do
    merchant = create(:merchant)
    authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)

    results = { charge: nil, reversal: nil }
    threads = []

    # Try to charge and reverse the same authorize concurrently
    threads << Thread.new do
      results[:charge] = ChargeTransaction.create(
        merchant: merchant,
        referenced_transaction: authorize,
        amount: 100.0,
        customer_email: "charge@test.com"
      )
    end

    threads << Thread.new do
      results[:reversal] = ReversalTransaction.create(
        merchant: merchant,
        referenced_transaction: authorize,
        customer_email: "reversal@test.com"
      )
    end

    threads.each(&:join)

    # Only ONE should succeed (either charge or reversal, not both)
    successful = [ results[:charge], results[:reversal] ].compact.select(&:persisted?)
    expect(successful.length).to eq(1)

    # Verify final state is consistent
    authorize.reload
    if results[:charge]&.persisted?
      expect(ChargeTransaction.where(referenced_transaction: authorize).exists?).to be true
      expect(ReversalTransaction.where(referenced_transaction: authorize).exists?).to be false
    else
      expect(authorize.status).to eq("reversed")
      expect(ReversalTransaction.where(referenced_transaction: authorize).exists?).to be true
      expect(ChargeTransaction.where(referenced_transaction: authorize).exists?).to be false
    end
  end
end
