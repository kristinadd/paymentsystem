class Transactions::Factory
  REGISTRY = {
    "authorize" => AuthorizeTransaction,
    "charge" => ChargeTransaction,
    "refund" => RefundTransaction,
    "reversal" => ReversalTransaction
  }.freeze

  TYPES = REGISTRY.keys.freeze

  def self.create(type:, **attributes)
    transaction_class = resolve_transaction_class(type)
    transaction_class.create!(attributes)
  end

  def self.resolve_transaction_class(type)
    transaction_class = REGISTRY[type&.downcase]

    unless transaction_class
      raise ArgumentError, "Invalid transaction type: #{type}. Must be one of: #{TYPES.join(", ")}"
    end

    transaction_class
  end
end
