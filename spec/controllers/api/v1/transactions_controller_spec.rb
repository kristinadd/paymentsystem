require "rails_helper"

RSpec.describe Api::V1::TransactionsController, type: :request do
  let(:merchant) { create(:merchant) }
  let(:valid_params) do
    {
      data: {
        type: "authorize",
        merchant_id: merchant.id,
        amount: 100.50,
        customer_email: "customer@example.com",
        customer_phone: "1234567890"
      }
    }
  end

  describe "POST /api/v1/transactions" do
    context "with valid parameters" do
      it "creates a transaction and returns correct JSON format" do
        post "/api/v1/transactions", params: valid_params, as: :json

        puts "Status: #{response.status}"
        puts "Body: #{response.body[0..200]}" if response.status != 201

        expect {
          post "/api/v1/transactions", params: valid_params, as: :json
        }.to change(Transaction, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["data"]).to include(
          "uuid" => be_present,
          "type" => "authorize",
          "amount" => "100.5",  # BigDecimal serializes to string (correct for money)
          "status" => "approved",
          "customer_email" => "customer@example.com",
          "customer_phone" => "1234567890",
          "created_at" => be_present,
          "updated_at" => be_present
        )

        # Ensure internal fields are not exposed
        expect(json["data"]).not_to have_key("id")
        expect(json["data"]).not_to have_key("merchant_id")
        expect(json["data"]).not_to have_key("referenced_transaction_id")
      end
    end

    context "with invalid parameters" do
      it "returns 400 when data wrapper is missing" do
        post "/api/v1/transactions", params: { type: "authorize" }, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Request must include 'data' wrapper")
      end

      it "returns 400 with inactive merchant" do
        inactive_merchant = create(:merchant, :inactive)
        valid_params[:data][:merchant_id] = inactive_merchant.id
        post "/api/v1/transactions", params: valid_params, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["errors"]["merchant_id"]).to eq("Merchant is not active")
      end

      it "returns all validation errors at once" do
        invalid_params = {
          data: {
            type: "invalid_type",
            merchant_id: 999999,
            amount: -10,
            customer_email: "not-an-email",
            customer_phone: "abc"
          }
        }
        post "/api/v1/transactions", params: invalid_params, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "type" => include("Invalid transaction type"),
          "merchant_id" => "Merchant not found",
          "amount" => "Amount must be greater than 0",
          "customer_email" => "Customer email is invalid",
          "customer_phone" => "Customer phone is invalid"
        )
      end
    end

    context "with different transaction types" do
      it "creates AuthorizeTransaction" do
        valid_params[:data][:type] = "authorize"
        post "/api/v1/transactions", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["type"]).to eq("authorize")
        expect(Transaction.last.type).to eq("AuthorizeTransaction")
      end

      it "creates ChargeTransaction" do
        authorize_tx = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100.50)
        valid_params[:data][:type] = "charge"
        valid_params[:data][:referenced_transaction_id] = authorize_tx.uuid
        post "/api/v1/transactions", params: valid_params, as: :json

        if response.status != 201
          puts "❌ Response status: #{response.status}"
          puts "Response body: #{response.body}"
        end

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["type"]).to eq("charge")
        expect(Transaction.last.type).to eq("ChargeTransaction")
      end

      it "creates RefundTransaction" do
        charge_tx = create(:charge_transaction, merchant: merchant, status: :approved, amount: 100.50)
        valid_params[:data][:type] = "refund"
        valid_params[:data][:referenced_transaction_id] = charge_tx.uuid
        post "/api/v1/transactions", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["type"]).to eq("refund")
        expect(Transaction.last.type).to eq("RefundTransaction")
      end

      it "creates ReversalTransaction" do
        authorize_tx = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100.50)
        valid_params[:data][:type] = "reversal"
        valid_params[:data][:referenced_transaction_id] = authorize_tx.uuid
        valid_params[:data].delete(:amount)  # Reversals don't have their own amount
        post "/api/v1/transactions", params: valid_params, as: :json

        if response.status != 201
          puts "❌ Response status: #{response.status}"
          puts "Response body: #{response.body}"
        end

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["type"]).to eq("reversal")
        expect(Transaction.last.type).to eq("ReversalTransaction")
      end
    end
  end
end
