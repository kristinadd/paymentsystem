# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_30_094756) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "key_digest", null: false
    t.string "key_prefix", null: false
    t.datetime "last_used_at"
    t.bigint "merchant_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["merchant_id"], name: "index_api_keys_on_merchant_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email", null: false
    t.string "name", null: false
    t.decimal "total_transaction_sum", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["email"], name: "index_merchants_on_email", unique: true
    t.index ["user_id"], name: "index_merchants_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_phone"
    t.bigint "merchant_id", null: false
    t.bigint "referenced_transaction_id"
    t.integer "status", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["referenced_transaction_id", "type"], name: "index_unique_charge_per_authorize", unique: true, where: "((type)::text = 'ChargeTransaction'::text)"
    t.index ["referenced_transaction_id", "type"], name: "index_unique_refund_per_charge", unique: true, where: "((type)::text = 'RefundTransaction'::text)"
    t.index ["referenced_transaction_id", "type"], name: "index_unique_reversal_per_authorize", unique: true, where: "((type)::text = 'ReversalTransaction'::text)"
    t.index ["referenced_transaction_id"], name: "index_transactions_on_referenced_transaction_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["type"], name: "index_transactions_on_type"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_keys", "merchants"
  add_foreign_key "merchants", "users"
  add_foreign_key "transactions", "merchants"
  add_foreign_key "transactions", "transactions", column: "referenced_transaction_id"
end
