require "rails_helper"

RSpec.describe Transactions::Builder do
  let(:merchant) { create(:merchant) }
  let(:external_params) do
    {
      type: "authorize",
      merchant_id: merchant.id,
      amount: "100.50",
      status: "approved",
      customer_email: "customer@example.com",
      customer_phone: "1234567890"
    }
  end

  describe "#build" do
    context "with basic parameters" do
      it "builds internal params hash" do
        builder = described_class.new(external_params)
        result = builder.build

        expect(result).to include(
          type: "authorize",
          merchant_id: merchant.id,
          amount: "100.50",
          status: :approved,
          customer_email: "customer@example.com",
          customer_phone: "1234567890"
        )
      end

      it "converts status string to symbol" do
        builder = described_class.new(external_params)
        result = builder.build

        expect(result[:status]).to eq(:approved)
        expect(result[:status]).to be_a(Symbol)
      end

      it "defaults status to :approved when missing" do
        params = external_params.except(:status)
        builder = described_class.new(params)
        result = builder.build

        expect(result[:status]).to eq(:approved)
      end

      it "handles different status values" do
        %w[approved reversed refunded error].each do |status|
          params = external_params.merge(status: status)
          builder = described_class.new(params)
          result = builder.build

          expect(result[:status]).to eq(status.to_sym)
        end
      end
    end

    context "with referenced_transaction_id" do
      it "converts UUID to internal ID" do
        authorize_tx = create(:authorize_transaction, merchant: merchant)
        params = external_params.merge(
          type: "charge",
          referenced_transaction_id: authorize_tx.uuid
        )
        builder = described_class.new(params)
        result = builder.build

        expect(result[:referenced_transaction_id]).to eq(authorize_tx.id)
        expect(result[:referenced_transaction_id]).not_to eq(authorize_tx.uuid)
      end

      it "sets nil when UUID not found" do
        params = external_params.merge(
          type: "charge",
          referenced_transaction_id: "invalid-uuid"
        )
        builder = described_class.new(params)
        result = builder.build

        expect(result[:referenced_transaction_id]).to be_nil
      end

      it "omits key when referenced_transaction_id is not present" do
        builder = described_class.new(external_params)
        result = builder.build

        expect(result).not_to have_key(:referenced_transaction_id)
      end
    end

    context "with nil values" do
      it "compacts nil values from result" do
        params = external_params.merge(
          amount: nil,
          customer_phone: nil
        )
        builder = described_class.new(params)
        result = builder.build

        expect(result).not_to have_key(:amount)
        expect(result).not_to have_key(:customer_phone)
      end
    end

    context "for different transaction types" do
      it "builds params for authorize transaction" do
        params = external_params.merge(type: "authorize")
        builder = described_class.new(params)
        result = builder.build

        expect(result[:type]).to eq("authorize")
      end

      it "builds params for charge transaction" do
        authorize_tx = create(:authorize_transaction, merchant: merchant)
        params = external_params.merge(
          type: "charge",
          referenced_transaction_id: authorize_tx.uuid
        )
        builder = described_class.new(params)
        result = builder.build

        expect(result[:type]).to eq("charge")
        expect(result[:referenced_transaction_id]).to eq(authorize_tx.id)
      end

      it "builds params for refund transaction" do
        charge_tx = create(:charge_transaction, merchant: merchant)
        params = external_params.merge(
          type: "refund",
          referenced_transaction_id: charge_tx.uuid
        )
        builder = described_class.new(params)
        result = builder.build

        expect(result[:type]).to eq("refund")
        expect(result[:referenced_transaction_id]).to eq(charge_tx.id)
      end

      it "builds params for reversal transaction" do
        authorize_tx = create(:authorize_transaction, merchant: merchant)
        params = external_params.merge(
          type: "reversal",
          referenced_transaction_id: authorize_tx.uuid
        ).except(:amount)
        builder = described_class.new(params)
        result = builder.build

        expect(result[:type]).to eq("reversal")
        expect(result[:referenced_transaction_id]).to eq(authorize_tx.id)
        expect(result).not_to have_key(:amount)
      end
    end

    context "edge cases" do
      it "handles uppercase status" do
        params = external_params.merge(status: "APPROVED")
        builder = described_class.new(params)
        result = builder.build

        expect(result[:status]).to eq(:approved)
      end

      it "handles mixed case status" do
        params = external_params.merge(status: "ApProVeD")
        builder = described_class.new(params)
        result = builder.build

        expect(result[:status]).to eq(:approved)
      end

      it "preserves original type value" do
        params = external_params.merge(type: "Authorize")
        builder = described_class.new(params)
        result = builder.build

        expect(result[:type]).to eq("Authorize")
      end
    end
  end
end
