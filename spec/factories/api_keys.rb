FactoryBot.define do
  factory :api_key do
    merchant { nil }
    key_digest { "MyKeyDigest" }
    key_prefix { "MyKeyPrefix" }
    name { "MyName" }
    last_used_at { Time.current }
    expires_at { 1.year.from_now }
  end
end
