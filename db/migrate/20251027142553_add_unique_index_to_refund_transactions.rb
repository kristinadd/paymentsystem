class AddUniqueIndexToRefundTransactions < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions,
      [ :referenced_transaction_id, :type ],
      unique: true,
      where: "type = 'RefundTransaction'",
      name: 'index_unique_refund_per_charge'
  end
end
