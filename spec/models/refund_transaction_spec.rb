require 'rails_helper'

RSpec.describe RefundTransaction, type: :model do
  describe "validations" do
    context "referenced_transaction" do
      it "requires referenced_transaction" do
        refund = build(:refund_transaction, referenced_transaction: nil, create_charge: false, amount: nil)
        expect(refund).not_to be_valid
        expect(refund.errors[:referenced_transaction]).to include("can't be blank")
      end

      it "must reference ChargeTransaction" do
        authorize = create(:authorize_transaction)
        refund = build(:refund_transaction, referenced_transaction: authorize, create_charge: false)

        expect(refund).not_to be_valid
        expect(refund.errors[:referenced_transaction]).to include("must be a charge transaction")
      end

      it "is valid with ChargeTransaction" do
        charge = create(:charge_transaction)
        refund = build(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount)

        expect(refund).to be_valid
      end
    end

    context "amount validation" do
      it "requires amount" do
        refund = build(:refund_transaction, amount: nil, create_charge: false)
        expect(refund).not_to be_valid
        expect(refund.errors[:amount]).to include("can't be blank")
      end

      it "must match charge amount" do
        charge = create(:charge_transaction, amount: 100.0)
        refund = build(:refund_transaction, referenced_transaction: charge, amount: 50.0, create_charge: false)

        expect(refund).not_to be_valid
        expect(refund.errors[:amount]).to include("must match charge transaction amount")
      end

      it "is valid when matching charge amount" do
        charge = create(:charge_transaction, amount: 100.0)
        refund = build(:refund_transaction, referenced_transaction: charge, amount: 100.0, create_charge: false)

        expect(refund).to be_valid
      end
    end

    context "charge status" do
      it "sets status to error when charge is not approved" do
        refund = build(:refund_transaction, :with_error_charge)

        expect(refund).not_to be_valid
        expect(refund.status).to eq("error")
        expect(refund.errors[:referenced_transaction]).to include("must be an approved transaction")
      end

      it "keeps approved status when charge is approved" do
        charge = create(:charge_transaction, status: :approved)
        refund = build(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount)
        refund.valid?

        expect(refund.status).to eq("approved")
      end

      it "sets status to error when charge has error status" do
        charge = create(:charge_transaction, status: :approved)
        charge.update_column(:status, Transaction.statuses[:error])
        refund = build(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount, status: :approved)

        expect(refund).not_to be_valid
        expect(refund.status).to eq("error")
        expect(refund.errors[:referenced_transaction]).to include("must be an approved transaction")
      end
    end

    context "duplicate refunds" do
      it "prevents multiple refunds for same charge" do
        charge = create(:charge_transaction)
        refund1 = create(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount)

        expect(refund1).to be_persisted

        # Reload charge to get updated status
        charge.reload

        # Try to create second refund - charge is now "refunded"
        refund2 = build(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount)

        # Should be invalid with clear error message
        expect(refund2).not_to be_valid
        expect(refund2.errors[:referenced_transaction]).to include("must be an approved transaction")
      end
    end
  end

  describe "merchant status requirements" do
    context "when merchant is active" do
      let(:merchant) { create(:merchant) }

      it "allows transaction creation" do
        charge = create(:charge_transaction, merchant: merchant)
        refund = build(:refund_transaction, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: charge.amount)

        expect(refund).to be_valid
      end
    end

    context "when merchant is inactive" do
      let(:merchant) { create(:merchant, :inactive) }
      let(:active_merchant) { create(:merchant) }

      it "prevents transaction creation" do
        # Create authorize and charge with active merchant and matching amounts
        authorize = create(:authorize_transaction, merchant: active_merchant, amount: 100.0)
        charge = create(:charge_transaction, merchant: active_merchant, referenced_transaction: authorize, amount: 100.0, create_authorize: false)

        # Try to create refund with inactive merchant
        refund = build(:refund_transaction, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: charge.amount)

        expect(refund).not_to be_valid
        expect(refund.errors[:merchant]).to include("is not active")
      end
    end
  end

  describe "charge status update" do
    it "changes charge status to refunded when refund is approved" do
      charge = create(:charge_transaction, status: :approved)
      expect(charge.status).to eq("approved")

      refund = create(:refund_transaction, referenced_transaction: charge, create_charge: false, amount: charge.amount, status: :approved)

      expect(refund).to be_persisted
      charge.reload
      expect(charge.status).to eq("refunded")
    end

    it "does not change charge status when refund is error" do
      charge = create(:charge_transaction, status: :approved)
      refund = create(:refund_transaction, :with_error_status, referenced_transaction: charge, create_charge: false, amount: charge.amount)

      expect(refund.status).to eq("error")
      charge.reload
      expect(charge.status).to eq("approved")
    end
  end

  describe "merchant total transaction sum" do
    let(:merchant) { create(:merchant, total_transaction_sum: 0) }

    it "decreases merchant total when refund is approved" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      charge = create(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100.0)

      merchant.reload
      expect(merchant.total_transaction_sum).to eq(100.0)

      refund = create(:refund_transaction, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: 100.0)

      expect(refund).to be_persisted
      merchant.reload
      expect(merchant.total_transaction_sum).to eq(0.0)
    end

    it "does not change merchant total when refund is error" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      charge = create(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100.0)

      merchant.reload
      expect(merchant.total_transaction_sum).to eq(100.0)

      refund = create(:refund_transaction, :with_error_status, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: 100.0)

      expect(refund.status).to eq("error")
      merchant.reload
      expect(merchant.total_transaction_sum).to eq(100.0)
    end
  end

  describe "create refund transaction chain" do
    let(:merchant) { create(:merchant) }

    it "creates valid refund transaction chain" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      charge = create(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100.0)
      refund = create(:refund_transaction, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: 100.0)

      expect(refund).to be_persisted
      expect(refund.referenced_transaction).to eq(charge)
      expect(refund.amount).to eq(100.0)
      expect(charge.reload.status).to eq("refunded")
    end

    it "is part of transaction chain" do
      refund = create(:refund_transaction)
      charge = refund.referenced_transaction
      authorize = charge.referenced_transaction

      expect(authorize.referencing_transactions).to include(charge)
      expect(charge.referencing_transactions).to include(refund)
      expect(refund.referenced_transaction).to eq(charge)
    end
  end
end
