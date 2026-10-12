class ChangeColumnsNullOnProduct < ActiveRecord::Migration[8.1]
  def change
    change_table :products do |t|
      # Zorunlu olanları güncelle
      t.change :name, :string, null: false
      t.change :description, :text, null: false
      t.change :price, :decimal, null: false, precision: 10, scale: 2
      t.change :stock, :integer, null: false
      t.change :is_active, :boolean,null: false, default: true
    end
  end
end
