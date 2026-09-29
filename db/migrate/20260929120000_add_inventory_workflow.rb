class AddInventoryWorkflow < ActiveRecord::Migration[8.1]
  def up
    add_column :items, :name, :string
    execute "UPDATE items SET name = item_type"
    change_column_null :items, :name, false

    create_table :inventory_units do |t|
      t.references :item, null: false, foreign_key: true
      t.string :barcode, null: false
      t.string :state, null: false
      t.timestamps
    end
    add_index :inventory_units, :barcode, unique: true
    add_check_constraint :inventory_units, "state IN ('in', 'out')", name: "inventory_units_state"
    add_check_constraint :inventory_units, "length(trim(barcode)) > 0", name: "inventory_units_barcode"

    create_table :movement_batches do |t|
      t.string :direction, null: false
      t.string :taken_by
      t.string :client_code
      t.string :request_key, null: false
      t.string :payload_digest, null: false
      t.timestamps
    end
    add_index :movement_batches, :request_key, unique: true
    add_check_constraint :movement_batches, "direction IN ('in', 'out')", name: "movement_batches_direction"
    add_check_constraint :movement_batches,
      "direction <> 'out' OR (taken_by IS NOT NULL AND length(trim(taken_by)) > 0)",
      name: "movement_batches_taken_by"

    create_table :movements do |t|
      t.references :movement_batch, null: false, foreign_key: true
      t.references :inventory_unit, null: false, foreign_key: true
      t.datetime :scanned_at, null: false
      t.timestamps
    end
    add_index :movements, [ :movement_batch_id, :inventory_unit_id ], unique: true
  end

  def down
    drop_table :movements
    drop_table :movement_batches
    drop_table :inventory_units
    remove_column :items, :name
  end
end