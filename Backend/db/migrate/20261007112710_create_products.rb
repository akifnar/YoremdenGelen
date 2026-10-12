class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.integer :stock
      t.string :sku
      t.string :category
      t.string :slug
      t.boolean :is_active

      t.timestamps
    end
  end
end
