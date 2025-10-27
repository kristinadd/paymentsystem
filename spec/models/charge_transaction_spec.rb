require 'rails_helper'

RSpec.describe ChargeTransaction, type: :model do
  describe "create charge transaction" do
    context "when authorize is approved" do
      it "creates charge with approved status" do
        authorize = create(:authorize_transaction, status: :approved, amount: 100)
        charge = create(:charge_transaction, referenced_transaction: authorize, amount: 100, create_authorize: false)

        expect(charge).to be_persisted
        expect(charge.status).to eq("approved")
      end
    end
  end

  describe "amount matching validation" do
    it "is valid when amount matches authorize amount" do
      authorize = create(:authorize_transaction, status: :approved, amount: 100)
      charge = build(:charge_transaction, referenced_transaction: authorize, amount: 100, create_authorize: false)

      expect(charge).to be_valid
    end

    it "is invalid when amount differs from authorize amount" do
      authorize = create(:authorize_transaction, status: :approved, amount: 100)
      charge = build(:charge_transaction, referenced_transaction: authorize, amount: 50, create_authorize: false)

      expect(charge).not_to be_valid
      expect(charge.errors[:amount]).to include("must match authorize transaction amount")
    end
  end

  describe "duplicate charge prevention" do
    it "prevents creating multiple charges for same authorize" do
      authorize = create(:authorize_transaction, status: :approved, amount: 100)

      # First charge - should succeed
      charge1 = create(:charge_transaction, referenced_transaction: authorize, amount: 100, create_authorize: false)
      expect(charge1).to be_persisted

      # Second charge - should fail
      charge2 = build(:charge_transaction, referenced_transaction: authorize, amount: 100, create_authorize: false)
      expect(charge2).not_to be_valid
      expect(charge2.errors[:referenced_transaction]).to include("already has a charge transaction")
    end
  end

  describe "merchant total_transaction_sum update" do
    let(:merchant) { create(:merchant, total_transaction_sum: 0) }

    it "updates merchant total when charge is created with approved status" do
      authorize = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100)

      expect {
        create(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100, create_authorize: false)
      }.to change { merchant.reload.total_transaction_sum }.from(0).to(100)
    end

    it "does not update merchant total when charge has error status" do
      authorize = create(:authorize_transaction, merchant: merchant, status: :error, amount: 100)

      charge = ChargeTransaction.new(
        merchant: merchant,
        referenced_transaction: authorize,
        amount: 100,
        customer_email: "test@test.com"
      )

      # Should be invalid due to authorize having error status
      expect(charge).not_to be_valid
      expect(charge.status).to eq("error")
      expect(charge.errors[:referenced_transaction]).to include("must be an approved or refunded transaction")
      
      # Merchant total should not change
      expect(merchant.reload.total_transaction_sum).to eq(0)
    end
  end

  describe "create charge transaction" do
    it "creates valid charge transaction" do
      merchant = create(:merchant)
      authorize = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100)

      charge = ChargeTransaction.create!(
        merchant: merchant,
        referenced_transaction: authorize,
        amount: 100,
        customer_email: "customer@test.com"
      )

      expect(charge).to be_persisted
      expect(charge.type).to eq("ChargeTransaction")
      expect(charge.referenced_transaction).to eq(authorize)
      expect(charge.amount).to eq(100)
      expect(charge.status).to eq("approved")
    end
  end
end
