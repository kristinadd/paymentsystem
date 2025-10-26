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

  validates :uuid, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
