class CreateProductPurchases < ActiveRecord::Migration[8.1]
  # Yorum yetkisi ve alıcının ürüne verdiği tek puan. Her (alıcı, ürün) çifti için tek satır; yorumların
  # kendisi burada değil comments tablosunda tutulur.
  def change
    create_table :product_purchases do |t|
      # (user_id, product_id) benzersiz index'i user_id ile başladığı için ayrı user_id index'i gerekmez.
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :product, null: false, foreign_key: { on_delete: :cascade }
      t.integer :rating, limit: 2
      t.timestamps
    end

    add_index :product_purchases, [ :user_id, :product_id ], unique: true
    add_check_constraint :product_purchases, "rating IS NULL OR rating BETWEEN 1 AND 5", name: "product_purchases_rating_range"
  end
end
