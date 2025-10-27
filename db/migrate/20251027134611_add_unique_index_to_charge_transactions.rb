class AddUniqueIndexToChargeTransactions < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions,
              [ :referenced_transaction_id, :type ],
              unique: true,
              where: "type = 'ChargeTransaction'",
              name: 'index_unique_charge_per_authorize'
  end
end
