require "rails_helper"

RSpec.describe Api::V1::TransactionsController, type: :request do
  let(:merchant) { create(:merchant) }
  let(:api_key_result) { ApiKeyGenerator.generate(merchant: merchant) }
  let(:api_key) { api_key_result[:raw_key] }

  let(:valid_data) do
    {
      type: "authorize",
      merchant_id: merchant.id,
      amount: 100.50,
      customer_email: "customer@example.com",
      customer_phone: "1234567890"
    }
  end

  # Shared examples for both JSON and XML formats
  shared_examples "creates transaction successfully" do |format|
    it "creates a transaction and returns #{format.upcase} response" do
      expect {
        make_request(format, valid_data)
      }.to change(Transaction, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include(content_type_for(format))

      parsed = parse_response(format, response.body)
      expect(parsed["data"]).to include(
        "uuid" => be_present,
        "type" => "authorize",
        "amount" => "100.5",
        "status" => "approved",
        "customer_email" => "customer@example.com",
        "customer_phone" => "1234567890",
        "created_at" => be_present,
        "updated_at" => be_present
      )

      # Ensure internal fields are not exposed
      expect(parsed["data"]).not_to have_key("id")
      expect(parsed["data"]).not_to have_key("merchant_id")
      expect(parsed["data"]).not_to have_key("referenced_transaction_id")
    end
  end

  shared_examples "returns validation errors" do |format|
    it "returns 400 when data wrapper is missing in #{format.upcase}" do
      make_request_without_wrapper(format, valid_data)

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to include(content_type_for(format))

      parsed = parse_response(format, response.body)
      expect(parsed["error"]).to eq("Request must include 'data' wrapper")
    end

    it "returns 400 with inactive merchant in #{format.upcase}" do
      inactive_merchant = create(:merchant, :inactive)
      # Need API key for inactive merchant to get past authentication
      inactive_key_result = ApiKeyGenerator.generate(merchant: inactive_merchant)
      invalid_data = valid_data.merge(merchant_id: inactive_merchant.id)

      case format
      when :json
        post "/api/v1/transactions",
             params: { data: invalid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer #{inactive_key_result[:raw_key]}"
             }
      when :xml
        post "/api/v1/transactions",
             params: { data: invalid_data }.to_xml(root: "request", skip_instruct: true),
             headers: {
               "Content-Type" => "application/xml",
               "Authorization" => "Bearer #{inactive_key_result[:raw_key]}"
             }
      end

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to include(content_type_for(format))

      parsed = parse_response(format, response.body)
      expect(parsed["errors"]["merchant_id"]).to eq("Merchant is not active")
    end

    it "returns all validation errors at once in #{format.upcase}" do
      # Use a valid merchant but with completely invalid transaction data
      invalid_data = {
        type: "invalid_type",
        merchant_id: merchant.id,  # Use valid merchant for authentication
        amount: -10,
        customer_email: "not-an-email",
        customer_phone: "abc"
      }

      case format
      when :json
        post "/api/v1/transactions",
             params: { data: invalid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer #{api_key}"
             }
      when :xml
        post "/api/v1/transactions",
             params: { data: invalid_data }.to_xml(root: "request", skip_instruct: true),
             headers: {
               "Content-Type" => "application/xml",
               "Authorization" => "Bearer #{api_key}"
             }
      end

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to include(content_type_for(format))

      parsed = parse_response(format, response.body)
      expect(parsed["errors"]).to include(
        "type" => include("Invalid transaction type"),
        "amount" => "Amount must be greater than 0",
        "customer_email" => "Customer email is invalid",
        "customer_phone" => "Customer phone is invalid"
      )
    end
  end

  shared_examples "creates different transaction types" do |format|
    it "creates AuthorizeTransaction in #{format.upcase}" do
      data = valid_data.merge(type: "authorize")
      make_request(format, data)

      expect(response).to have_http_status(:created)
      parsed = parse_response(format, response.body)
      expect(parsed["data"]["type"]).to eq("authorize")
      expect(Transaction.last.type).to eq("AuthorizeTransaction")
    end

    it "creates ChargeTransaction in #{format.upcase}" do
      authorize_tx = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100.50)
      data = valid_data.merge(type: "charge", referenced_transaction_id: authorize_tx.uuid)
      make_request(format, data)

      expect(response).to have_http_status(:created)
      parsed = parse_response(format, response.body)
      expect(parsed["data"]["type"]).to eq("charge")
      expect(Transaction.last.type).to eq("ChargeTransaction")
    end

    it "creates RefundTransaction in #{format.upcase}" do
      charge_tx = create(:charge_transaction, merchant: merchant, status: :approved, amount: 100.50)
      data = valid_data.merge(type: "refund", referenced_transaction_id: charge_tx.uuid)
      make_request(format, data)

      expect(response).to have_http_status(:created)
      parsed = parse_response(format, response.body)
      expect(parsed["data"]["type"]).to eq("refund")
      expect(Transaction.last.type).to eq("RefundTransaction")
    end

    it "creates ReversalTransaction in #{format.upcase}" do
      authorize_tx = create(:authorize_transaction, merchant: merchant, status: :approved, amount: 100.50)
      data = valid_data.merge(type: "reversal", referenced_transaction_id: authorize_tx.uuid)
      data.delete(:amount)  # Reversals don't have their own amount
      make_request(format, data)

      expect(response).to have_http_status(:created)
      parsed = parse_response(format, response.body)
      expect(parsed["data"]["type"]).to eq("reversal")
      expect(Transaction.last.type).to eq("ReversalTransaction")
    end
  end

  describe "POST /api/v1/transactions" do
    context "with JSON format" do
      let(:format) { :json }

      context "with valid parameters" do
        include_examples "creates transaction successfully", :json
      end

      context "with invalid parameters" do
        include_examples "returns validation errors", :json
      end

      context "with different transaction types" do
        include_examples "creates different transaction types", :json
      end
    end

    context "with XML format" do
      let(:format) { :xml }

      context "with valid parameters" do
        include_examples "creates transaction successfully", :xml
      end

      context "with invalid parameters" do
        include_examples "returns validation errors", :xml
      end

      context "with different transaction types" do
        include_examples "creates different transaction types", :xml
      end
    end

    context "with unsupported format" do
      it "returns 400 error" do
        post "/api/v1/transactions",
             params: { data: valid_data }.to_yaml,
             headers: { "Content-Type" => "application/yaml" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "authentication" do
      it "returns 401 when no API key is provided" do
        post "/api/v1/transactions",
             params: { data: valid_data }.to_json,
             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        parsed = JSON.parse(response.body)
        expect(parsed["error"]).to eq("API key is missing")
      end

      it "returns 401 when invalid API key is provided" do
        post "/api/v1/transactions",
             params: { data: valid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer sk_invalid_key"
             }

        expect(response).to have_http_status(:unauthorized)
        parsed = JSON.parse(response.body)
        expect(parsed["error"]).to eq("Invalid API key")
      end

      it "returns 401 when expired API key is provided" do
        expired_api_key = create(:api_key, :expired, merchant: merchant)
        raw_key = "sk_expired_#{SecureRandom.hex(32)}"
        expired_api_key.update_column(:key_digest, Digest::SHA256.hexdigest(raw_key))

        post "/api/v1/transactions",
             params: { data: valid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer #{raw_key}"
             }

        expect(response).to have_http_status(:unauthorized)
        parsed = JSON.parse(response.body)
        expect(parsed["error"]).to eq("API key has expired")
      end

      it "returns 400 when merchant_id does not match authenticated merchant" do
        other_merchant = create(:merchant)
        invalid_data = valid_data.merge(merchant_id: other_merchant.id)

        post "/api/v1/transactions",
             params: { data: invalid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer #{api_key}"
             }

        expect(response).to have_http_status(:bad_request)
        parsed = JSON.parse(response.body)
        expect(parsed["error"]).to include("merchant_id must match the authenticated merchant")
      end

      it "tracks API key usage" do
        api_key_record = api_key_result[:api_key]
        expect(api_key_record.last_used_at).to be_nil

        post "/api/v1/transactions",
             params: { data: valid_data }.to_json,
             headers: {
               "Content-Type" => "application/json",
               "Authorization" => "Bearer #{api_key}"
             }

        expect(api_key_record.reload.last_used_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  private

  # Helper to make requests in different formats
  def make_request(format, data)
    case format
    when :json
      post "/api/v1/transactions",
           params: { data: data }.to_json,
           headers: {
             "Content-Type" => "application/json",
             "Authorization" => "Bearer #{api_key}"
           }
    when :xml
      post "/api/v1/transactions",
           params: { data: data }.to_xml(root: "request", skip_instruct: true),
           headers: {
             "Content-Type" => "application/xml",
             "Authorization" => "Bearer #{api_key}"
           }
    end
  end

  # Helper to make requests without data wrapper
  def make_request_without_wrapper(format, data)
    case format
    when :json
      post "/api/v1/transactions",
           params: data.to_json,
           headers: {
             "Content-Type" => "application/json",
             "Authorization" => "Bearer #{api_key}"
           }
    when :xml
      post "/api/v1/transactions",
           params: data.to_xml(root: "request", skip_instruct: true),
           headers: {
             "Content-Type" => "application/xml",
             "Authorization" => "Bearer #{api_key}"
           }
    end
  end

  # Helper to parse responses in different formats
  def parse_response(format, body)
    case format
    when :json
      JSON.parse(body)
    when :xml
      Hash.from_xml(body)["response"]
    end
  end

  # Helper to get expected content type
  def content_type_for(format)
    case format
    when :json
      "application/json"
    when :xml
      "application/xml"
    end
  end
end
