class AuthorizeTransaction < Transaction
  validates :amount, presence: true
  validates :referenced_transaction, absence: true
end
