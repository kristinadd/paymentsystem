require "rails_helper"

RSpec.describe Formatters::Factory do
  describe ".for_request" do
    let(:request) { double("request") }

    context "with application/json content type" do
      it "returns Json" do
        allow(request).to receive(:content_type).and_return("application/json")

        formatter = described_class.for_request(request)

        expect(formatter).to be_a(Formatters::Json)
      end
    end

    context "with application/xml content type" do
      it "returns Xml" do
        allow(request).to receive(:content_type).and_return("application/xml")

        formatter = described_class.for_request(request)

        expect(formatter).to be_a(Formatters::Xml)
      end
    end

    context "with text/xml content type" do
      it "returns Xml" do
        allow(request).to receive(:content_type).and_return("text/xml")

        formatter = described_class.for_request(request)

        expect(formatter).to be_a(Formatters::Xml)
      end
    end

    context "with unsupported content type" do
      it "raises BadRequest error" do
        allow(request).to receive(:content_type).and_return("application/yaml")

        expect {
          described_class.for_request(request)
        }.to raise_error(ActionController::BadRequest, /Unsupported Content-Type/)
      end

      it "includes supported types in error message" do
        allow(request).to receive(:content_type).and_return("text/plain")

        expect {
          described_class.for_request(request)
        }.to raise_error(ActionController::BadRequest, /application\/json/)
      end
    end
  end

  describe ".for_content_type" do
    context "with application/json" do
      it "returns Json" do
        formatter = described_class.for_content_type("application/json")

        expect(formatter).to be_a(Formatters::Json)
      end
    end

    context "with application/xml" do
      it "returns Xml" do
        formatter = described_class.for_content_type("application/xml")

        expect(formatter).to be_a(Formatters::Xml)
      end
    end

    context "with unsupported content type" do
      it "raises BadRequest error" do
        expect {
          described_class.for_content_type("text/csv")
        }.to raise_error(ActionController::BadRequest, /Unsupported Content-Type/)
      end
    end
  end
end
