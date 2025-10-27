class RefundTransaction < Transaction
  validates :referenced_transaction, presence: true
  validates :amount, presence: true

  validate :referenced_must_be_charge
  validate :amount_must_match_charge, if: :referenced_transaction_valid?
  validate :charge_not_already_refunded, if: :referenced_transaction_valid?

  before_validation :set_default_status, on: :create
  before_validation :check_referenced_transaction_status

  after_commit :update_charge_status, if: -> { saved_change_to_status? && approved? }
  after_commit :update_merchant_total, if: -> { saved_change_to_status? && approved? }

  private

  def set_default_status
    self.status ||= :approved
  end

  def check_referenced_transaction_status
    return unless referenced_transaction
    return if status == :error

    unless referenced_transaction.approved?
      self.status = :error
    end
  end

  def referenced_must_be_charge
    if referenced_transaction && !referenced_transaction.is_a?(ChargeTransaction)
      errors.add(:referenced_transaction, "must be a charge transaction")
    end
  end

  def referenced_transaction_valid?
    referenced_transaction&.is_a?(ChargeTransaction) &&
      referenced_transaction.approved?
  end

  def amount_must_match_charge
    if amount != referenced_transaction.amount
      errors.add(:amount, "must match charge transaction amount")
    end
  end

  def charge_not_already_refunded
    existing_refund = referenced_transaction.referencing_transactions
                        .where(type: "RefundTransaction")
                        .where.not(id: id)
                        .exists?

    if existing_refund
      errors.add(:referenced_transaction, "already has a refund transaction")
    end
  end

  def update_charge_status
    referenced_transaction.update!(status: :refunded)
  end

  def update_merchant_total
    merchant.increment!(:total_transaction_sum, -amount)
  end
end
