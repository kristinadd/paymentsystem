require 'rails_helper'

RSpec.describe ReversalTransaction, type: :model do
  describe "validations" do
    context "referenced_transaction" do
      it "requires referenced_transaction" do
        reversal = build(:reversal_transaction, referenced_transaction: nil, create_authorize: false)
        expect(reversal).not_to be_valid
        expect(reversal.errors[:referenced_transaction]).to include("can't be blank")
      end

      it "must reference AuthorizeTransaction" do
        charge = create(:charge_transaction)
        reversal = build(:reversal_transaction, referenced_transaction: charge, create_authorize: false)

        expect(reversal).not_to be_valid
        expect(reversal.errors[:referenced_transaction]).to include("must be an authorize transaction")
      end

      it "is valid with AuthorizeTransaction" do
        authorize = create(:authorize_transaction)
        reversal = build(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)

        expect(reversal).to be_valid
      end
    end

    context "amount" do
      it "requires amount to be nil" do
        reversal = build(:reversal_transaction, amount: 100.0)
        expect(reversal).not_to be_valid
        expect(reversal.errors[:amount]).to include("must be blank")
      end

      it "is valid with nil amount" do
        reversal = build(:reversal_transaction, amount: nil)
        expect(reversal).to be_valid
      end
    end

    context "authorize status" do
      it "sets status to error when authorize is not approved" do
        authorize = create(:authorize_transaction, status: :approved)
        authorize.update_column(:status, Transaction.statuses[:error])
        reversal = build(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)

        expect(reversal).not_to be_valid
        expect(reversal.status).to eq("error")
        expect(reversal.errors[:referenced_transaction]).to include("must be an approved transaction")
      end

      it "keeps approved status when authorize is approved" do
        authorize = create(:authorize_transaction, status: :approved)
        reversal = build(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)
        reversal.valid?

        expect(reversal.status).to eq("approved")
      end
    end

    context "authorize already charged" do
      it "prevents reversal if authorize has been charged" do
        reversal = build(:reversal_transaction, :with_charged_authorize)

        expect(reversal).not_to be_valid
        expect(reversal.errors[:referenced_transaction]).to include("has already been charged")
      end

      it "allows reversal if authorize has NOT been charged" do
        authorize = create(:authorize_transaction)
        reversal = build(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)

        expect(reversal).to be_valid
      end
    end

    context "duplicate reversals" do
      it "prevents multiple reversals for same authorize" do
        authorize = create(:authorize_transaction)
        reversal1 = create(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)

        expect(reversal1).to be_persisted

        # Reload authorize to get updated status
        authorize.reload

        # Try to create second reversal - authorize is now "reversed"
        reversal2 = build(:reversal_transaction, referenced_transaction: authorize, create_authorize: false)

        # Should be invalid with clear error message
        expect(reversal2).not_to be_valid
        expect(reversal2.errors[:referenced_transaction]).to include("must be an approved transaction")
      end
    end
  end

  describe "STI type column" do
    it "automatically sets type to ReversalTransaction" do
      reversal = create(:reversal_transaction)
      expect(reversal.type).to eq("ReversalTransaction")
    end

    it "can be queried by type" do
      create(:reversal_transaction)
      expect(ReversalTransaction.count).to eq(1)
      expect(Transaction.count).to eq(2) # Authorize + Reversal
    end
  end

  describe "merchant status requirements" do
    context "when merchant is active" do
      let(:merchant) { create(:merchant) }

      it "allows transaction creation" do
        authorize = create(:authorize_transaction, merchant: merchant)
        reversal = build(:reversal_transaction, merchant: merchant, referenced_transaction: authorize, create_authorize: false)

        expect(reversal).to be_valid
      end
    end

    context "when merchant is inactive" do
      let(:merchant) { create(:merchant, :inactive) }
      let(:active_merchant) { create(:merchant) }

      it "prevents transaction creation" do
        # Create authorize with active merchant
        authorize = create(:authorize_transaction, merchant: active_merchant, amount: 100.0)

        # Try to create reversal with inactive merchant
        reversal = build(:reversal_transaction, merchant: merchant, referenced_transaction: authorize, create_authorize: false)

        expect(reversal).not_to be_valid
        expect(reversal.errors[:merchant]).to include("is not active")
      end
    end
  end

  describe "authorize status update" do
    it "changes authorize status to reversed when reversal is approved" do
      authorize = create(:authorize_transaction, status: :approved)
      expect(authorize.status).to eq("approved")

      reversal = create(:reversal_transaction, referenced_transaction: authorize, create_authorize: false, status: :approved)

      expect(reversal).to be_persisted
      authorize.reload
      expect(authorize.status).to eq("reversed")
    end

    it "does not change authorize status when reversal is error" do
      authorize = create(:authorize_transaction, status: :approved)
      reversal = create(:reversal_transaction, :with_error_status, referenced_transaction: authorize, create_authorize: false)

      expect(reversal.status).to eq("error")
      authorize.reload
      expect(authorize.status).to eq("approved")
    end
  end

  describe "merchant total transaction sum" do
    let(:merchant) { create(:merchant, total_transaction_sum: 0) }

    it "does not change merchant total when reversal is approved" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)

      merchant.reload
      expect(merchant.total_transaction_sum).to eq(0)

      reversal = create(:reversal_transaction, merchant: merchant, referenced_transaction: authorize, create_authorize: false)

      expect(reversal).to be_persisted
      merchant.reload
      expect(merchant.total_transaction_sum).to eq(0) # Still 0, no money moved
    end
  end

  describe "business logic" do
    let(:merchant) { create(:merchant) }

    it "creates valid reversal transaction" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      reversal = create(:reversal_transaction, merchant: merchant, referenced_transaction: authorize, create_authorize: false)

      expect(reversal).to be_persisted
      expect(reversal.referenced_transaction).to eq(authorize)
      expect(reversal.amount).to be_nil
      expect(authorize.reload.status).to eq("reversed")
    end

    it "prevents charging a reversed authorize" do
      authorize = create(:authorize_transaction, merchant: merchant, amount: 100.0)
      reversal = create(:reversal_transaction, merchant: merchant, referenced_transaction: authorize, create_authorize: false)

      authorize.reload
      expect(authorize.status).to eq("reversed")

      # Try to create charge for reversed authorize
      charge = build(:charge_transaction, merchant: merchant, referenced_transaction: authorize, amount: 100.0, create_authorize: false)

      expect(charge).not_to be_valid
      expect(charge.status).to eq("error")
      expect(charge.errors[:referenced_transaction]).to include("must be an approved or refunded transaction")
    end

    it "is part of transaction chain" do
      reversal = create(:reversal_transaction)
      authorize = reversal.referenced_transaction

      expect(authorize.referencing_transactions).to include(reversal)
      expect(reversal.referenced_transaction).to eq(authorize)
    end
  end
end
