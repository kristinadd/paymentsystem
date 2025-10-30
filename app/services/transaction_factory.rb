class TransactionFactory
  TYPES = [ "authorize", "charge", "refund", "reversal" ].freeze

  def self.create(type:, **attributes)
    transaction_class = resolve_transaction_class(type)
    transaction_class.create!(attributes)
  end

  def self.resolve_transaction_class(type)
    case type&.downcase
    when "authorize"
      AuthorizeTransaction
    when "charge"
      ChargeTransaction
    when "refund"
      RefundTransaction
    when "reversal"
      ReversalTransaction
    else
      raise ArgumentError, "Invalid transaction type: #{type}. Must be one of: #{TYPES.join(", ")}"
    end
  end
end
