class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :type, null: false

      t.references :merchant, null: false, foreign_key: true
      t.references :referenced_transaction, foreign_key: { to_table: :transactions }

      t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.integer :status, null: false
      t.string :customer_email, null: false
      t.string :customer_phone

      t.timestamps
    end

    add_index :transactions, :uuid, unique: true
    add_index :transactions, :type
    add_index :transactions, :status
  end
end
