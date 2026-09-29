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

ActiveRecord::Schema[8.1].define(version: 2026_09_29_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "inventory_units", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "barcode", null: false
    t.string "state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_inventory_units_on_barcode", unique: true
    t.index ["item_id"], name: "index_inventory_units_on_item_id"
    t.check_constraint "length(TRIM(BOTH FROM barcode)) > 0", name: "inventory_units_barcode"
    t.check_constraint "state::text = ANY (ARRAY['in'::character varying, 'out'::character varying]::text[])", name: "inventory_units_state"
  end

  create_table "items", force: :cascade do |t|
    t.string "item_type", null: false
    t.string "variant"
    t.string "origin", null: false
    t.string "status", default: "new", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
  end

  create_table "movement_batches", force: :cascade do |t|
    t.string "direction", null: false
    t.string "taken_by"
    t.string "client_code"
    t.string "request_key", null: false
    t.string "payload_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_key"], name: "index_movement_batches_on_request_key", unique: true
    t.check_constraint "direction::text <> 'out'::text OR taken_by IS NOT NULL AND length(TRIM(BOTH FROM taken_by)) > 0", name: "movement_batches_taken_by"
    t.check_constraint "direction::text = ANY (ARRAY['in'::character varying, 'out'::character varying]::text[])", name: "movement_batches_direction"
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "movement_batch_id", null: false
    t.bigint "inventory_unit_id", null: false
    t.datetime "scanned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_unit_id"], name: "index_movements_on_inventory_unit_id"
    t.index ["movement_batch_id", "inventory_unit_id"], name: "index_movements_on_movement_batch_id_and_inventory_unit_id", unique: true
    t.index ["movement_batch_id"], name: "index_movements_on_movement_batch_id"
  end

  add_foreign_key "inventory_units", "items"
  add_foreign_key "movements", "inventory_units"
  add_foreign_key "movements", "movement_batches"
end
