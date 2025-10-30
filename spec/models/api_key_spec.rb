require "rails_helper"

RSpec.describe ApiKey, type: :model do
  let(:merchant) { create(:merchant) }

  describe "associations" do
    it { should belong_to(:merchant) }
  end

  describe "validations" do
    it { should validate_presence_of(:key_digest) }
    it { should validate_presence_of(:key_prefix) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "validates uniqueness of key_digest" do
      create(:api_key, merchant: merchant)
      should validate_uniqueness_of(:key_digest)
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns non-expired keys" do
        active_key = create(:api_key, merchant: merchant, expires_at: nil)
        future_key = create(:api_key, merchant: merchant, expires_at: 1.day.from_now)
        expired_key = create(:api_key, :expired, merchant: merchant)

        expect(ApiKey.active).to include(active_key, future_key)
        expect(ApiKey.active).not_to include(expired_key)
      end
    end
  end

  describe ".authenticate" do
    it "returns the API key when given a valid raw key" do
      result = ApiKeyGenerator.generate(merchant: merchant)
      raw_key = result[:raw_key]

      found_key = ApiKey.authenticate(raw_key)
      expect(found_key).to eq(result[:api_key])
    end

    it "returns nil when given an invalid raw key" do
      expect(ApiKey.authenticate("sk_invalid_key")).to be_nil
    end

    it "returns nil when given a blank key" do
      expect(ApiKey.authenticate("")).to be_nil
      expect(ApiKey.authenticate(nil)).to be_nil
    end
  end

  describe "#expired?" do
    it "returns false when expires_at is nil" do
      api_key = create(:api_key, merchant: merchant, expires_at: nil)
      expect(api_key.expired?).to be false
    end

    it "returns false when expires_at is in the future" do
      api_key = create(:api_key, merchant: merchant, expires_at: 1.day.from_now)
      expect(api_key.expired?).to be false
    end

    it "returns true when expires_at is in the past" do
      api_key = create(:api_key, :expired, merchant: merchant)
      expect(api_key.expired?).to be true
    end
  end

  describe "#active?" do
    it "returns true when not expired" do
      api_key = create(:api_key, merchant: merchant, expires_at: nil)
      expect(api_key.active?).to be true
    end

    it "returns false when expired" do
      api_key = create(:api_key, :expired, merchant: merchant)
      expect(api_key.active?).to be false
    end
  end

  describe "#touch_last_used!" do
    it "updates the last_used_at timestamp" do
      api_key = create(:api_key, merchant: merchant, last_used_at: nil)

      expect {
        api_key.touch_last_used!
      }.to change { api_key.reload.last_used_at }.from(nil)
    end

    it "updates last_used_at to current time" do
      api_key = create(:api_key, merchant: merchant)
      api_key.touch_last_used!

      expect(api_key.reload.last_used_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#revoke!" do
    it "sets expires_at to current time" do
      api_key = create(:api_key, merchant: merchant, expires_at: nil)

      expect {
        api_key.revoke!
      }.to change { api_key.reload.expires_at }.from(nil)

      expect(api_key.expires_at).to be_within(1.second).of(Time.current)
    end

    it "makes the key expired" do
      api_key = create(:api_key, merchant: merchant)

      api_key.revoke!

      expect(api_key.expired?).to be true
      expect(api_key.active?).to be false
    end
  end

  describe "#display_key" do
    it "returns the key prefix with ellipsis" do
      api_key = create(:api_key, merchant: merchant, key_prefix: "sk_abc1234")

      expect(api_key.display_key).to eq("sk_abc1234...")
    end

    it "never shows the full key" do
      result = ApiKeyGenerator.generate(merchant: merchant)
      api_key = result[:api_key]

      expect(api_key.display_key).not_to include(result[:raw_key])
      expect(api_key.display_key).to end_with("...")
    end
  end
end
