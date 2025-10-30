require "rails_helper"

RSpec.describe ApiKeyGenerator do
  let(:merchant) { create(:merchant) }

  describe ".generate" do
    it "generates an API key for a merchant" do
      result = described_class.generate(merchant: merchant)

      expect(result[:raw_key]).to be_present
      expect(result[:api_key]).to be_a(ApiKey)
      expect(result[:api_key].merchant).to eq(merchant)
    end

    it "generates a key with the correct prefix" do
      result = described_class.generate(merchant: merchant)

      expect(result[:raw_key]).to start_with("sk_")
    end

    it "generates a key with the correct length" do
      result = described_class.generate(merchant: merchant)

      # sk_ (3 chars) + 64 hex chars (32 bytes * 2)
      expect(result[:raw_key].length).to eq(67)
    end

    it "generates unique keys" do
      result1 = described_class.generate(merchant: merchant)
      result2 = described_class.generate(merchant: merchant)

      expect(result1[:raw_key]).not_to eq(result2[:raw_key])
    end

    it "stores the hashed key, not the raw key" do
      result = described_class.generate(merchant: merchant)

      # The stored digest should NOT equal the raw key
      expect(result[:api_key].key_digest).not_to eq(result[:raw_key])

      # The stored digest should be a SHA256 hash
      expect(result[:api_key].key_digest.length).to eq(64) # SHA256 hex length
    end

    it "stores the key prefix for display" do
      result = described_class.generate(merchant: merchant)

      # Prefix should be first 10 characters
      expect(result[:api_key].key_prefix).to eq(result[:raw_key][0, 10])
      expect(result[:api_key].key_prefix).to start_with("sk_")
    end

    it "accepts an optional name" do
      result = described_class.generate(merchant: merchant, name: "Production API Key")

      expect(result[:api_key].name).to eq("Production API Key")
    end

    it "accepts an optional expiration date" do
      expires_at = 1.year.from_now

      result = described_class.generate(merchant: merchant, expires_at: expires_at)

      expect(result[:api_key].expires_at).to be_within(1.second).of(expires_at)
    end

    it "can verify the generated key" do
      result = described_class.generate(merchant: merchant)
      raw_key = result[:raw_key]

      # Hash the raw key the same way
      hashed = Digest::SHA256.hexdigest(raw_key)

      # Should match what's stored
      expect(result[:api_key].key_digest).to eq(hashed)
    end
  end
end
