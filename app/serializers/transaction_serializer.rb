class TransactionSerializer
  def initialize(transaction)
    @transaction = transaction
  end

  def as_json
    {
      uuid: @transaction.uuid,
      type: external_type,
      amount: @transaction.amount,
      status: @transaction.status,
      customer_email: @transaction.customer_email,
      customer_phone: @transaction.customer_phone,
      referenced_transaction_uuid: @transaction.referenced_transaction&.uuid,
      created_at: @transaction.created_at,
      updated_at: @transaction.updated_at
    }.compact
  end

  private

  def external_type
    case @transaction.type
    when "AuthorizeTransaction"
      "authorize"
    when "ChargeTransaction"
      "charge"
    when "RefundTransaction"
      "refund"
    when "ReversalTransaction"
      "reversal"
    else
      raise ArgumentError, "Unknown transaction type: #{@transaction.type}. Must be one of: #{TransactionFactory::TYPES.join(", ")}"
    end
  end
end
