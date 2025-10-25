class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name, null: false
      t.text :description
      t.string :email, null: false
      t.boolean :active
      t.decimal :total_transaction_sum, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :merchants, :email, unique: true
  end
end
