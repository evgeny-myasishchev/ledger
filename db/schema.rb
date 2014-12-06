# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141206094249) do

  create_table "currency_rates", force: true do |t|
    t.string   "from",       null: false
    t.string   "to",         null: false
    t.float    "rate",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "currency_rates", ["from", "to"], name: "index_currency_rates_on_from_and_to", unique: true

  create_table "projections_accounts", force: true do |t|
    t.string  "ledger_id",           null: false
    t.string  "aggregate_id",        null: false
    t.integer "sequential_number",   null: false
    t.integer "owner_user_id",       null: false
    t.string  "authorized_user_ids", null: false
    t.integer "category_id"
    t.string  "currency_code",       null: false
    t.string  "name",                null: false
    t.string  "unit"
    t.integer "balance",             null: false
    t.boolean "is_closed",           null: false
  end

  add_index "projections_accounts", ["aggregate_id"], name: "index_projections_accounts_on_aggregate_id", unique: true
  add_index "projections_accounts", ["ledger_id", "sequential_number"], name: "index_projections_accounts_on_ledger_id_and_sequential_number", unique: true
  add_index "projections_accounts", ["ledger_id"], name: "index_projections_accounts_on_ledger_id"

  create_table "projections_categories", force: true do |t|
    t.string  "ledger_id",           null: false
    t.integer "category_id",         null: false
    t.integer "display_order",       null: false
    t.string  "name",                null: false
    t.string  "authorized_user_ids", null: false
  end

  add_index "projections_categories", ["ledger_id", "category_id"], name: "index_projections_categories_on_ledger_id_and_category_id", unique: true

  create_table "projections_ledgers", force: true do |t|
    t.string  "aggregate_id",        null: false
    t.integer "owner_user_id",       null: false
    t.string  "name",                null: false
    t.string  "currency_code",       null: false
    t.string  "authorized_user_ids"
  end

  add_index "projections_ledgers", ["aggregate_id"], name: "index_projections_ledgers_on_aggregate_id", unique: true

  create_table "projections_meta", force: true do |t|
    t.string  "projection_id", null: false
    t.integer "version",       null: false
  end

  create_table "projections_tags", force: true do |t|
    t.string  "ledger_id",           null: false
    t.integer "tag_id",              null: false
    t.string  "name",                null: false
    t.string  "authorized_user_ids", null: false
  end

  add_index "projections_tags", ["ledger_id", "tag_id"], name: "index_projections_tags_on_ledger_id_and_tag_id", unique: true

  create_table "projections_transactions", force: true do |t|
    t.string   "transaction_id",                           null: false
    t.string   "account_id",                               null: false
    t.integer  "type_id",                                  null: false
    t.integer  "amount",                                   null: false
    t.string   "tag_ids"
    t.text     "comment"
    t.datetime "date"
    t.boolean  "is_transfer",              default: false, null: false
    t.string   "sending_account_id"
    t.string   "sending_transaction_id"
    t.string   "receiving_account_id"
    t.string   "receiving_transaction_id"
  end

  add_index "projections_transactions", ["account_id"], name: "index_projections_transactions_on_account_id"
  add_index "projections_transactions", ["transaction_id"], name: "index_projections_transactions_on_transaction_id", unique: true

  create_table "snapshots", force: true do |t|
    t.string  "aggregate_id", null: false
    t.integer "version",      null: false
    t.binary  "data",         null: false
  end

  add_index "snapshots", ["aggregate_id"], name: "index_snapshots_on_aggregate_id", unique: true

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
