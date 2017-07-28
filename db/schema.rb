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

ActiveRecord::Schema.define(version: 20170721164017) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "candlesticks", force: :cascade do |t|
    t.string   "exchange"
    t.string   "pair"
    t.datetime "timestamp",                          null: false
    t.decimal  "open",      precision: 32, scale: 8, null: false
    t.decimal  "high",      precision: 32, scale: 8, null: false
    t.decimal  "low",       precision: 32, scale: 8, null: false
    t.decimal  "close",     precision: 32, scale: 8, null: false
    t.integer  "interval",                           null: false
  end

  add_index "candlesticks", ["timestamp", "pair", "exchange"], name: "index_candlesticks_on_timestamp_and_pair_and_exchange", unique: true, using: :btree

end
