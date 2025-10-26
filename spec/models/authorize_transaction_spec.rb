require 'rails_helper'

RSpec.describe AuthorizeTransaction, type: :model do
  describe "create authorize transaction" do
    let(:merchant) { create(:merchant) }

    it "creates valid authorize transaction" do
      authorize = AuthorizeTransaction.create(
        merchant: merchant,
        amount: 100.00,
        status: :approved,
        customer_email: "customer@test.com"
      )

      expect(authorize).to be_persisted
      expect(authorize.merchant).to eq(merchant)
      expect(authorize.amount).to eq(100.00)
      expect(authorize.type).to eq("AuthorizeTransaction")
    end

    it "is the root of transaction chain" do
      authorize = create(:authorize_transaction)
      expect(authorize.referenced_transaction).to be_nil
      expect(authorize.referencing_transactions).to be_empty
    end
  end

  describe "merchant status requirements" do
    context "when merchant is active" do
      let(:merchant) { create(:merchant, active: true) }

      it "creates valid authorize transaction" do
        authorize = AuthorizeTransaction.create(
          merchant: merchant,
          amount: 100.00,
          status: :approved,
          customer_email: "customer@test.com"
        )

        expect(authorize).to be_persisted
        expect(authorize.merchant).to eq(merchant)
        expect(authorize.amount).to eq(100.00)
        expect(authorize.type).to eq("AuthorizeTransaction")
      end
    end

    context "when merchant is inactive" do
      let(:merchant) { create(:merchant, :inactive) }

      it "does not create valid authorize transaction" do
        authorize = AuthorizeTransaction.create(
          merchant: merchant,
          amount: 100.00,
          status: :approved,
          customer_email: "customer@test.com"
        )

        expect(authorize).not_to be_persisted
        expect(authorize.errors[:merchant]).to include("is not active")
      end
    end
  end
end
