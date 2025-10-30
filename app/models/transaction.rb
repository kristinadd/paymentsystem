class Transaction < ApplicationRecord
  belongs_to :merchant

  belongs_to :referenced_transaction,
             class_name: "Transaction",
             optional: true

  has_many :referencing_transactions,
           class_name: "Transaction",
           foreign_key: :referenced_transaction_id,
           dependent: :restrict_with_error

  enum :status, {
    approved: 0,
    reversed: 1,
    refunded: 2,
    error: 3
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }, unless: :reversal_transaction?
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :merchant_must_be_active

  private

  def reversal_transaction?
    type == "ReversalTransaction"
  end

  def merchant_must_be_active
    if merchant&.active? == false
      errors.add(:merchant, "is not active")
    end
  end

  # Shared helper methods for child transactions

  def set_default_status
    self.status ||= :approved
  end

  def check_referenced_status(allowed_statuses = [ :approved ])
    return unless referenced_transaction
    return if status == :error

    unless Array(allowed_statuses).any? { |s| referenced_transaction.status == s.to_s }
      self.status = :error
      status_list = allowed_statuses.size == 1 ? "an #{allowed_statuses.first}" : "an #{allowed_statuses.map(&:to_s).join(' or ')}"
      errors.add(:referenced_transaction, "must be #{status_list} transaction")
    end
  end
end
