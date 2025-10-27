class ChargeTransaction < Transaction
  validates :referenced_transaction, presence: true
  validates :amount, presence: true

  validate :referenced_must_be_authorize
  validate :amount_must_match_authorize, if: :referenced_transaction_valid?
  validate :authorize_not_already_charged, if: :referenced_transaction_valid?

  before_validation :set_default_status, on: :create
  before_validation :check_referenced_transaction_status
  before_validation :lock_referenced_transaction, if: -> { referenced_transaction.present? }

  after_commit :process_approved_charge, if: -> { saved_change_to_status? && approved? }

  private

  def set_default_status
    self.status ||= :approved
  end

  def check_referenced_transaction_status
    return unless referenced_transaction
    return if status == :error

    unless referenced_transaction.approved? || referenced_transaction.refunded?
      self.status = :error
      errors.add(:referenced_transaction, "must be an approved or refunded transaction")
    end
  end

  def referenced_must_be_authorize
    if referenced_transaction && !referenced_transaction.is_a?(AuthorizeTransaction)
      errors.add(:referenced_transaction, "must be an authorize transaction")
    end
  end

  def referenced_transaction_valid?
    referenced_transaction&.is_a?(AuthorizeTransaction) &&
      (referenced_transaction.approved? || referenced_transaction.refunded?)
  end

  def amount_must_match_authorize
    if amount != referenced_transaction.amount
      errors.add(:amount, "must match authorize transaction amount")
    end
  end

  def authorize_not_already_charged
    existing_charge = referenced_transaction.referencing_transactions
                        .where(type: "ChargeTransaction")
                        .where.not(id: id)
                        .exists?

    if existing_charge
      errors.add(:referenced_transaction, "already has a charge transaction")
    end
  end

  def process_approved_charge
    ApplicationRecord.transaction do
      merchant.increment!(:total_transaction_sum, amount)
    end
  end

  def lock_referenced_transaction
    referenced_transaction.lock!
  end
end
