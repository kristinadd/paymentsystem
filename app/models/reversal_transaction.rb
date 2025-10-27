class ReversalTransaction < Transaction
  validates :referenced_transaction, presence: true
  validates :amount, absence: true

  validate :referenced_must_be_authorize
  validate :authorize_not_charged, if: :referenced_transaction_valid?
  validate :authorize_not_already_reversed, if: :referenced_transaction_valid?

  before_validation :set_default_status, on: :create
  before_validation :check_referenced_transaction_status
  before_validation :lock_referenced_transaction, if: -> { referenced_transaction.present? }

  after_commit :process_approved_reversal, if: -> { saved_change_to_status? && approved? }

  private

  def set_default_status
    self.status ||= :approved
  end

  def check_referenced_transaction_status
    return unless referenced_transaction
    return if status == :error

    unless referenced_transaction.approved?
      self.status = :error
      errors.add(:referenced_transaction, "must be an approved transaction")
    end
  end

  def referenced_must_be_authorize
    if referenced_transaction && !referenced_transaction.is_a?(AuthorizeTransaction)
      errors.add(:referenced_transaction, "must be an authorize transaction")
    end
  end

  def referenced_transaction_valid?
    referenced_transaction&.is_a?(AuthorizeTransaction) &&
      referenced_transaction.approved?
  end

  def authorize_not_charged
    existing_charge = referenced_transaction.referencing_transactions
                        .where(type: "ChargeTransaction")
                        .exists?

    if existing_charge
      errors.add(:referenced_transaction, "has already been charged")
    end
  end

  def authorize_not_already_reversed
    existing_reversal = referenced_transaction.referencing_transactions
                          .where(type: "ReversalTransaction")
                          .where.not(id: id)
                          .exists?

    if existing_reversal
      errors.add(:referenced_transaction, "has already been reversed")
    end
  end

  def process_approved_reversal
    ApplicationRecord.transaction do
      referenced_transaction.update!(status: :reversed)
    end
  end

  def lock_referenced_transaction
    referenced_transaction.lock!
  end
end
