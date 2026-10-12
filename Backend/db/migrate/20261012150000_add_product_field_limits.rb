class AddProductFieldLimits < ActiveRecord::Migration[8.1]
  def up
    change_column :products, :name, :string, limit: 120, null: false
    change_column :products, :description, :text, limit: 2_000, null: false
    change_column :products, :category, :string, limit: 40
    change_column :products, :price, :decimal, precision: 10, scale: 2, null: false
    change_column :products, :stock, :integer, null: false
    change_column :products, :sku, :string, limit: 50
    change_column :products, :slug, :string, limit: 140
    change_column :products, :is_active, :boolean, null: false, default: true

    execute <<~SQL
      UPDATE products
      SET category = 'Diğer Yöresel Ürünler'
      WHERE category IS NULL OR category NOT IN (
        'Peynir', 'Zeytin', 'Zeytinyağı', 'Et ve Şarküteri',
        'Tatlılar', 'Hamur İşleri', 'Süt Ürünleri', 'Diğer Yöresel Ürünler'
      )
    SQL
    change_column_null :products, :category, false
  end

  def down
    change_column :products, :name, :string, limit: nil
    change_column :products, :description, :text, limit: nil
    change_column :products, :category, :string, limit: nil, null: true
    change_column :products, :sku, :string, limit: nil
    change_column :products, :slug, :string, limit: nil
  end
end
