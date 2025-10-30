class ApiKey < ApplicationRecord
  belongs_to :merchant

  validates :key_digest, presence: true, uniqueness: true
  validates :key_prefix, presence: true
  validates :name, length: { maximum: 255 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def active?
    !expired?
  end

  def revoke!
    update!(expires_at: Time.current)
  end

  # Display-friendly format (never show full key after creation)
  def display_key
    "#{key_prefix}..."
  end
end
