require 'rails_helper'

RSpec.describe Imports::MerchantService, type: :service do
  let(:user) { create(:user, role: :merchant) }
  let(:valid_row) do
    {
      "merchant_name" => "Test Merchant",
      "merchant_email" => "merchant@example.com",
      "merchant_description" => "A test merchant"
    }
  end

  describe '#call' do
    context 'with valid data' do
      it 'creates a merchant' do
        expect {
          described_class.new(valid_row, user).call
        }.to change(Merchant, :count).by(1)
      end

      it 'returns the created merchant' do
        merchant = described_class.new(valid_row, user).call

        expect(merchant).to be_a(Merchant)
        expect(merchant.name).to eq("Test Merchant")
        expect(merchant.email).to eq("merchant@example.com")
        expect(merchant.description).to eq("A test merchant")
        expect(merchant.active).to be true
      end

      it 'links merchant to the user' do
        merchant = described_class.new(valid_row, user).call

        expect(merchant.user).to eq(user)
      end

      it 'handles missing description gracefully' do
        row = valid_row.merge("merchant_description" => nil)
        merchant = described_class.new(row, user).call

        expect(merchant).to be_a(Merchant)
        expect(merchant.description).to be_nil
      end
    end

    context 'with invalid data' do
      it 'returns nil when merchant creation fails' do
        invalid_row = valid_row.merge("merchant_email" => "not-an-email")
        service = described_class.new(invalid_row, user)

        expect(service.call).to be_nil
        expect(service.errors).not_to be_empty
      end

      it 'does not create merchant when email validation fails' do
        invalid_row = valid_row.merge("merchant_email" => "not-an-email")
        service = described_class.new(invalid_row, user)

        expect {
          service.call
        }.not_to change(Merchant, :count)
      end

      it 'returns nil when user is not a merchant role' do
        admin_user = create(:user, :admin)
        service = described_class.new(valid_row, admin_user)

        expect(service.call).to be_nil
        expect(service.errors).not_to be_empty
      end
    end

    context 'with missing required fields' do
      it 'raises error when merchant_name is missing' do
        row = valid_row.merge("merchant_name" => "")
        service = described_class.new(row, user)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Merchant name is required")
      end

      it 'raises error when merchant_email is missing' do
        row = valid_row.merge("merchant_email" => "")
        service = described_class.new(row, user)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Merchant email is required")
      end

      it 'raises error when user is blank' do
        service = described_class.new(valid_row, nil)

        expect {
          service.call
        }.to raise_error(ArgumentError, "User cannot be blank")
      end

      it 'raises error when row is blank' do
        service = described_class.new(nil, user)

        expect {
          service.call
        }.to raise_error(ArgumentError, "Row data cannot be blank")
      end
    end
  end
end
