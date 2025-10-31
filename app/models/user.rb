class User < ApplicationRecord
  has_one :merchant

  enum :role, {
    merchant: 0,
    admin: 1
  }

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  validate :admin_cannot_have_merchant

  before_save :normalize_email

  def accessible_transactions
    if admin?
      Transaction.all
    elsif merchant? && merchant.present?
      merchant.transactions
    else
      Transaction.none
    end
  end

  def accessible_merchants
    if admin?
      Merchant.all
    elsif merchant? && merchant.present?
      Merchant.where(id: merchant.id)
    else
      Merchant.none
    end
  end

  private

  def normalize_email
    self.email = email.downcase if email.present?
  end

  def admin_cannot_have_merchant
    if admin? && merchant.present?
      errors.add(:merchant, "must be blank for admin role")
    end
  end
end
