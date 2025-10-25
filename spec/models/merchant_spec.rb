require 'rails_helper'

RSpec.describe Merchant, type: :model do
  describe "business logic" do
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
end
