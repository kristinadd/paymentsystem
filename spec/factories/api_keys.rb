FactoryBot.define do
  factory :api_key do
    merchant

    transient do
      raw_key { "sk_test_#{SecureRandom.hex(32)}" }
    end

    key_digest { Digest::SHA256.hexdigest(raw_key) }
    key_prefix { raw_key[0, 10] }
    name { "Test API Key" }
    last_used_at { nil }
    expires_at { nil }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :with_name do
      name { "Production API Key" }
    end
  end
end
