require "rails_helper"

RSpec.describe Formatters::XmlFormatter do
  let(:formatter) { described_class.new }
  let(:transaction) { create(:authorize_transaction, amount: 100.50) }

  describe "#parse" do
    context "with valid XML" do
      it "parses XML string into hash" do
        xml_string = <<~XML
          <request>
            <data>
              <type>authorize</type>
              <amount>100.50</amount>
            </data>
          </request>
        XML

        result = formatter.parse(xml_string)

        expect(result).to eq({ data: { type: "authorize", amount: "100.50" } })
      end

      it "symbolizes keys" do
        xml_string = <<~XML
          <request>
            <data>
              <merchant_id>123</merchant_id>
            </data>
          </request>
        XML

        result = formatter.parse(xml_string)

        expect(result.keys).to all(be_a(Symbol))
        expect(result[:data].keys).to all(be_a(Symbol))
      end
    end

    context "with invalid XML" do
      it "raises BadRequest error" do
        invalid_xml = "<data><unclosed>"

        expect {
          formatter.parse(invalid_xml)
        }.to raise_error(ActionController::BadRequest, /Invalid XML/)
      end
    end
  end

  describe "#serialize" do
    it "serializes transaction to XML" do
      result = formatter.serialize(transaction)
      parsed = Hash.from_xml(result)

      expect(parsed).to have_key("response")
      expect(parsed["response"]).to have_key("data")
      expect(parsed["response"]["data"]).to include(
        "uuid" => transaction.uuid,
        "type" => "authorize",
        "amount" => "100.5",
        "status" => transaction.status
      )
    end

    it "returns valid XML string" do
      result = formatter.serialize(transaction)

      expect { Hash.from_xml(result) }.not_to raise_error
      expect(result).to start_with("<?xml")
    end

    it "includes XML declaration" do
      result = formatter.serialize(transaction)

      expect(result).to include('<?xml version="1.0" encoding="UTF-8"?>')
    end
  end

  describe "#serialize_error" do
    it "serializes hash errors" do
      errors = { merchant_id: "is required", amount: "must be positive" }
      result = formatter.serialize_error(errors)
      parsed = Hash.from_xml(result)

      expect(parsed["response"]).to have_key("errors")
      expect(parsed["response"]["errors"]).to include(
        "merchant_id" => "is required",
        "amount" => "must be positive"
      )
    end

    it "serializes ActiveModel::Errors" do
      invalid_transaction = build(:authorize_transaction, merchant: nil)
      invalid_transaction.valid?

      result = formatter.serialize_error(invalid_transaction.errors)
      parsed = Hash.from_xml(result)

      expect(parsed["response"]).to have_key("errors")
      expect(parsed["response"]["errors"]).to be_a(Hash)
    end

    it "serializes string errors" do
      result = formatter.serialize_error("Something went wrong")
      parsed = Hash.from_xml(result)

      expect(parsed["response"]).to eq({ "error" => "Something went wrong" })
    end

    it "returns valid XML" do
      errors = { field: "error message" }
      result = formatter.serialize_error(errors)

      expect { Hash.from_xml(result) }.not_to raise_error
    end
  end

  describe "#content_type" do
    it "returns application/xml" do
      expect(formatter.content_type).to eq("application/xml")
    end
  end
end
