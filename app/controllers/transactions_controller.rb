class TransactionsController < ApplicationController
  def index
    @transactions = current_user.accessible_transactions
                                 .includes(:merchant, :referenced_transaction)
                                 .order(created_at: :desc)
                                 .limit(25)
  end
end
