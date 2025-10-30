class ApiKey < ApplicationRecord
  belongs_to :merchant

  validates :key_digest, presence: true, uniqueness: true
  validates :key_prefix, presence: true
  validates :name, length: { maximum: 255 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.authenticate(raw_key)
    return nil if raw_key.blank?

    key_digest = Digest::SHA256.hexdigest(raw_key)
    find_by(key_digest: key_digest)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def active?
    !expired?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def revoke!
    update!(expires_at: Time.current)
  end

  def display_key
    "#{key_prefix}..."
  end
end
