require "rails_helper"

RSpec.describe Transactions::Validator do
  let(:merchant) { create(:merchant) }
  let(:valid_params) do
    {
      type: "authorize",
      merchant_id: merchant.id,
      amount: 100.50,
      customer_email: "customer@example.com",
      customer_phone: "1234567890"
    }
  end

  describe "#validate!" do
    context "with valid parameters" do
      it "returns true" do
        validator = described_class.new(valid_params)

        expect(validator.validate!).to be true
      end

      it "does not raise an error" do
        validator = described_class.new(valid_params)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with missing type" do
      it "raises ValidationError" do
        params = valid_params.except(:type)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        )
      end

      it "includes type error in errors hash" do
        params = valid_params.except(:type)
        validator = described_class.new(params)

        begin
          validator.validate!
        rescue Transactions::Validator::ValidationError => e
          expect(e.errors[:type]).to eq("Type is required")
        end
      end
    end

    context "with invalid type" do
      it "raises ValidationError" do
        params = valid_params.merge(type: "invalid_type")
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        )
      end

      it "includes type error with details" do
        params = valid_params.merge(type: "invalid_type")
        validator = described_class.new(params)

        begin
          validator.validate!
        rescue Transactions::Validator::ValidationError => e
          expect(e.errors[:type]).to include("Invalid transaction type")
        end
      end
    end

    context "with missing merchant_id" do
      it "raises ValidationError" do
        params = valid_params.except(:merchant_id)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        )
      end

      it "includes merchant_id error" do
        params = valid_params.except(:merchant_id)
        validator = described_class.new(params)

        begin
          validator.validate!
        rescue Transactions::Validator::ValidationError => e
          expect(e.errors[:merchant_id]).to eq("Merchant ID is required")
        end
      end
    end

    context "with non-existent merchant" do
      it "raises ValidationError" do
        params = valid_params.merge(merchant_id: 999999)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        )
      end

      it "includes merchant not found error" do
        params = valid_params.merge(merchant_id: 999999)
        validator = described_class.new(params)

        begin
          validator.validate!
        rescue Transactions::Validator::ValidationError => e
          expect(e.errors[:merchant_id]).to eq("Merchant not found")
        end
      end
    end

    context "with inactive merchant" do
      it "raises ValidationError" do
        inactive_merchant = create(:merchant, :inactive)
        params = valid_params.merge(merchant_id: inactive_merchant.id)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:merchant_id]).to eq("Merchant is not active")
        end
      end
    end

    context "with missing amount" do
      it "raises ValidationError for non-reversal transactions" do
        params = valid_params.except(:amount)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:amount]).to eq("Amount is required")
        end
      end

      it "does not raise error for reversal transactions" do
        params = valid_params.merge(type: "reversal").except(:amount)
        validator = described_class.new(params)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with invalid amount" do
      it "raises ValidationError for zero amount" do
        params = valid_params.merge(amount: 0)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:amount]).to eq("Amount must be greater than 0")
        end
      end

      it "raises ValidationError for negative amount" do
        params = valid_params.merge(amount: -100)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:amount]).to eq("Amount must be greater than 0")
        end
      end
    end

    context "with missing customer_email" do
      it "raises ValidationError" do
        params = valid_params.except(:customer_email)
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:customer_email]).to eq("Customer email is required")
        end
      end
    end

    context "with invalid customer_email" do
      it "raises ValidationError" do
        params = valid_params.merge(customer_email: "not-an-email")
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:customer_email]).to eq("Customer email is invalid")
        end
      end
    end

    context "with invalid customer_phone" do
      it "raises ValidationError for letters" do
        params = valid_params.merge(customer_phone: "abc123")
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:customer_phone]).to eq("Customer phone is invalid")
        end
      end

      it "raises ValidationError for too short phone" do
        params = valid_params.merge(customer_phone: "123")
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:customer_phone]).to eq("Customer phone is invalid")
        end
      end

      it "allows missing phone (optional field)" do
        params = valid_params.except(:customer_phone)
        validator = described_class.new(params)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with invalid status" do
      it "raises ValidationError" do
        params = valid_params.merge(status: "invalid_status")
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors[:status]).to include("Invalid status")
        end
      end
    end

    context "with multiple validation errors" do
      it "raises ValidationError with all errors" do
        params = {
          type: "invalid_type",
          merchant_id: 999999,
          amount: -10,
          customer_email: "not-an-email",
          customer_phone: "abc"
        }
        validator = described_class.new(params)

        expect { validator.validate! }.to raise_error(
          Transactions::Validator::ValidationError
        ) do |error|
          expect(error.errors).to include(
            type: include("Invalid transaction type"),
            merchant_id: "Merchant not found",
            amount: "Amount must be greater than 0",
            customer_email: "Customer email is invalid",
            customer_phone: "Customer phone is invalid"
          )
        end
      end
    end
  end

  describe "#valid?" do
    it "returns true for valid parameters" do
      validator = described_class.new(valid_params)

      expect(validator.valid?).to be true
    end

    it "returns false for invalid parameters" do
      params = valid_params.except(:type)
      validator = described_class.new(params)

      expect(validator.valid?).to be false
    end
  end

  describe "#errors" do
    it "returns empty hash for valid parameters" do
      validator = described_class.new(valid_params)
      validator.errors

      expect(validator.errors).to be_empty
    end

    it "returns errors hash for invalid parameters" do
      params = valid_params.except(:type)
      validator = described_class.new(params)

      expect(validator.errors).to include(type: "Type is required")
    end
  end
end
