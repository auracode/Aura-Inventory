class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :barcode, null: false
      t.string :name, null: false
      t.string :category
      t.text :description
      t.timestamps
    end

    add_index :items, :barcode, unique: true
  end
end