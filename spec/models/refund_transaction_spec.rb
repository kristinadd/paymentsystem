require 'rails_helper'

RSpec.describe RefundTransaction, type: :model do
  # Shared example: merchant status requirements
  it_behaves_like "enforces merchant status" do
    def build_transaction_with_active_merchant(merchant)
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      charge = create(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100.0, create_authorize: false)
      build(:refund_transaction, merchant: merchant, referenced_transaction: charge, create_charge: false, amount: charge.amount)
    end

    def build_transaction_with_inactive_merchant(inactive_merchant, active_merchant)
      authorize = create(:authorize_transaction, merchant: active_merchant, amount: 100.0)
      charge = create(:charge_transaction, merchant: active_merchant, referenced_transaction: authorize, amount: 100.0, create_authorize: false)
      build(:refund_transaction, merchant: inactive_merchant, referenced_transaction: charge, create_charge: false, amount: charge.amount)
    end
  end

  # Shared example: duplicate transaction prevention
  it_behaves_like "prevents duplicate transactions" do
    def create_parent_transaction
      create(:charge_transaction)
    end

    def create_child_transaction(parent)
      create(:refund_transaction, referenced_transaction: parent, create_charge: false, amount: parent.amount)
    end

    def build_child_transaction(parent)
      build(:refund_transaction, referenced_transaction: parent, create_charge: false, amount: parent.amount)
    end
  end

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
        expect(refund.errors[:referenced_transaction]).to include("must be approved transaction")
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
        expect(refund.errors[:referenced_transaction]).to include("must be approved transaction")
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
