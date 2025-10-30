class AuthorizeTransaction < Transaction
  validates :amount, presence: true
  validates :referenced_transaction, absence: true

  def self.external_type
    "authorize"
  end
end
