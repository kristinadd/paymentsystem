class Merchant < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :restrict_with_error
  has_many :api_keys, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :user_needs_to_be_merchant

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase if email.present?
  end

  def user_needs_to_be_merchant
    if user.present? && !user.merchant?
      errors.add(:user, "needs to have a merchant role")
    end
  end
end
