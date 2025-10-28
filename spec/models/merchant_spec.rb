require 'rails_helper'

RSpec.describe Merchant, type: :model do
  describe "validate user" do
    context "when user is admin" do
      it "does not create merchant" do
        admin = create(:user, :admin)
        merchant = build(:merchant, user: admin)

        expect(merchant).not_to be_valid
        expect(merchant.errors[:user]).to include("needs to have a merchant role")
      end
    end

    context "when user is merchant" do
      it "creates merchant" do
        merchant = create(:merchant)
        expect(merchant).to be_valid
      end
    end
  end

  describe "email uniqueness" do
    it "prevents duplicate emails" do
      create(:merchant, email: "duplicate@example.com")
      duplicate = build(:merchant, email: "duplicate@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it "is case insensitive" do
      create(:merchant, email: "user@EXAMPLE.com")
      duplicate = build(:merchant, email: "USER@example.com")

      expect(duplicate).not_to be_valid
    end
  end
end
