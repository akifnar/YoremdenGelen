class RemoveSlugFromProducts < ActiveRecord::Migration[8.1]
  # Ürün adresleri artık id ile kurulur (/urunler/:id); isimden türetilen slug'a gerek kalmadı.
  def up
    remove_column :products, :slug
  end

  def down
    add_column :products, :slug, :string, limit: 140
    execute "UPDATE products SET slug = 'urun-' || id"
  end
end
