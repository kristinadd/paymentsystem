FactoryBot.define do
  factory :api_key do
    merchant
    key_digest { Digest::SHA256.hexdigest("sk_test_#{SecureRandom.hex(32)}") }
    key_prefix { "sk_test_ab" }
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
