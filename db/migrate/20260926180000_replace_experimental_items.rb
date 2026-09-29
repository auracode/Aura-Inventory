class ReplaceExperimentalItems < ActiveRecord::Migration[8.1]
  def change
    # The experimental Item data is disposable; replace its table completely.
    drop_table :items do |t|
      t.string :barcode, null: false
      t.string :name, null: false
      t.string :category
      t.text :description
      t.timestamps
      t.index :barcode, unique: true
    end

    create_table :items do |t|
      t.string :item_type, null: false
      t.string :variant
      t.string :origin, null: false
      t.string :status, null: false, default: "new"
      t.timestamps
    end
  end
end