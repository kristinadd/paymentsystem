class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys, if_not_exists: true do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :key_digest, null: false
      t.string :key_prefix, null: false
      t.string :name
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true, if_not_exists: true
    add_index :api_keys, :merchant_id, if_not_exists: true
  end
end
