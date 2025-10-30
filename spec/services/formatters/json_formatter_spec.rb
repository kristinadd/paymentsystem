require "rails_helper"

RSpec.describe Formatters::JsonFormatter do
  let(:formatter) { described_class.new }
  let(:transaction) { create(:authorize_transaction, amount: 100.50) }

  describe "#parse" do
    context "with valid JSON" do
      it "parses JSON string into hash" do
        json_string = '{"data": {"type": "authorize", "amount": "100.50"}}'
        result = formatter.parse(json_string)

        expect(result).to eq({ data: { type: "authorize", amount: "100.50" } })
      end

      it "symbolizes keys" do
        json_string = '{"data": {"merchant_id": 123}}'
        result = formatter.parse(json_string)

        expect(result.keys).to all(be_a(Symbol))
        expect(result[:data].keys).to all(be_a(Symbol))
      end
    end

    context "with invalid JSON" do
      it "raises BadRequest error" do
        invalid_json = '{"data": invalid}'

        expect {
          formatter.parse(invalid_json)
        }.to raise_error(ActionController::BadRequest, /Invalid JSON/)
      end
    end
  end

  describe "#serialize" do
    it "serializes transaction to JSON" do
      result = formatter.serialize(transaction)
      parsed = JSON.parse(result)

      expect(parsed).to have_key("data")
      expect(parsed["data"]).to include(
        "uuid" => transaction.uuid,
        "type" => "authorize",
        "amount" => "100.5",
        "status" => transaction.status
      )
    end

    it "returns valid JSON string" do
      result = formatter.serialize(transaction)

      expect { JSON.parse(result) }.not_to raise_error
    end
  end

  describe "#serialize_error" do
    it "serializes hash errors" do
      errors = { merchant_id: "is required", amount: "must be positive" }
      result = formatter.serialize_error(errors)
      parsed = JSON.parse(result)

      expect(parsed).to eq({ "errors" => errors.stringify_keys })
    end

    it "serializes ActiveModel::Errors" do
      invalid_transaction = build(:authorize_transaction, merchant: nil)
      invalid_transaction.valid?

      result = formatter.serialize_error(invalid_transaction.errors)
      parsed = JSON.parse(result)

      expect(parsed).to have_key("errors")
      expect(parsed["errors"]).to be_a(Hash)
    end

    it "serializes string errors" do
      result = formatter.serialize_error("Something went wrong")
      parsed = JSON.parse(result)

      expect(parsed).to eq({ "error" => "Something went wrong" })
    end
  end

  describe "#content_type" do
    it "returns application/json" do
      expect(formatter.content_type).to eq("application/json")
    end
  end
end
