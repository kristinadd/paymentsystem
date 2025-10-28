require 'rails_helper'

RSpec.describe User, type: :model do
  describe "role-specific validations" do
    context "when role is merchant" do
      it "is valid without merchant" do
        user = create(:user, role: :merchant)
        expect(user).to be_valid
        expect(user.merchant).to be_nil
      end

      it "is valid with merchant" do
        user = create(:user, :with_merchant)
        expect(user).to be_valid
        expect(user.merchant).to be_present
      end
    end

    context "when role is admin" do
      it "is valid without merchant" do
        user = build(:user, :admin)
        expect(user).to be_valid
      end

      it "cannot change role to admin if user has a merchant" do
        user = create(:user, :with_merchant)

        user.role = :admin

        expect(user).not_to be_valid
        expect(user.errors[:merchant]).to include("must be blank for admin role")
      end
    end
  end

  describe "#accessible_transactions" do
    let!(:user1) { create(:user, :with_merchant) }
    let!(:user2) { create(:user, :with_merchant) }
    let(:merchant1) { user1.merchant }
    let(:merchant2) { user2.merchant }

    before do
      create(:authorize_transaction, merchant: merchant1, amount: 100)
      create(:authorize_transaction, merchant: merchant1, amount: 200)
      create(:authorize_transaction, merchant: merchant2, amount: 300)
    end

    context "when user is admin" do
      it "returns all transactions" do
        admin = create(:user, :admin)
        expect(admin.accessible_transactions.count).to eq(3)
      end
    end

    context "when user is merchant" do
      it "returns only their merchant's transactions" do
        transactions = user1.accessible_transactions

        expect(transactions.count).to eq(2)
        expect(transactions.pluck(:amount)).to match_array([ 100, 200 ])
      end

      it "does not see other merchants' transactions" do
        transactions = user1.accessible_transactions

        expect(transactions.where(merchant: merchant2)).to be_empty
      end

      it "returns no transactions when merchant has no merchant account" do
        merchant_user = create(:user, role: :merchant)
        expect(merchant_user.accessible_transactions).to be_empty
      end
    end
  end

  describe "email normalization" do
    it "downcases email before save" do
      user = create(:user, :admin, email: "TEST@EXAMPLE.COM")
      expect(user.reload.email).to eq("test@example.com")
    end
  end
end
