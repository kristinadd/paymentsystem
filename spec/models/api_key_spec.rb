require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  describe "create api key" do
    let(:merchant) { create(:merchant) }

    it "creates valid api key" do
      api_key = ApiKey.create(merchant: merchant, key_digest: "MyKeyDigest", key_prefix: "MyKeyPrefix", name: "MyName")
      expect(api_key).to be_persisted
    end

    it "is the root of transaction chain" do
      api_key = create(:api_key)
      expect(api_key.referenced_transaction).to be_nil
      expect(api_key.referencing_transactions).to be_empty
    end
  end

  describe "merchant status requirements" do
    context "when merchant is active" do
      let(:merchant) { create(:merchant, active: true) }

      it "creates valid api key" do
        api_key = ApiKey.create(merchant: merchant, key_digest: "MyKeyDigest", key_prefix: "MyKeyPrefix", name: "MyName")
        expect(api_key).to be_persisted
      end
    end
  end

  describe "merchant status requirements" do
    context "when merchant is inactive" do
      let(:merchant) { create(:merchant, active: false) }

      it "does not create valid api key" do
        api_key = ApiKey.create(merchant: merchant, key_digest: "MyKeyDigest", key_prefix: "MyKeyPrefix", name: "MyName")
        expect(api_key).not_to be_persisted
        expect(api_key.errors[:merchant]).to include("is not active")
      end
    end
  end
end
