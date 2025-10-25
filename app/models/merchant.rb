class Merchant < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase if email.present?
  end
end
