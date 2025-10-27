class AddUniqueIndexToReversalTransactions < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions,
      [ :referenced_transaction_id, :type ],
      unique: true,
      where: "type = 'ReversalTransaction'",
      name: 'index_unique_reversal_per_authorize'
  end
end
