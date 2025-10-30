class ApiKeyGenerator
  PREFIX = "sk_".freeze
  KEY_LENGTH = 32

  def self.generate(merchant:, name: nil, expires_at: nil)
    new(merchant: merchant, name: name, expires_at: expires_at).generate
  end

  def initialize(merchant:, name: nil, expires_at: nil)
    @merchant = merchant
    @name = name
    @expires_at = expires_at
  end

  def generate
    raw_key = generate_raw_key
    key_digest = hash_key(raw_key)
    key_prefix = extract_prefix(raw_key)

    api_key = ApiKey.create!(
      merchant: @merchant,
      key_digest: key_digest,
      key_prefix: key_prefix,
      name: @name,
      expires_at: @expires_at
    )

    # Return both the raw key (ONLY TIME IT'S VISIBLE!) and the record
    { raw_key: raw_key, api_key: api_key }
  end

  private

  def generate_raw_key
    "#{PREFIX}#{SecureRandom.hex(KEY_LENGTH)}"
  end

  def hash_key(raw_key)
    Digest::SHA256.hexdigest(raw_key)
  end

  def extract_prefix(raw_key)
    # Store first 10 characters for display (e.g., "sk_abc1234...")
    raw_key[0, 10]
  end
end
