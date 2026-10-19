class CreateComments < ActiveRecord::Migration[8.1]
  # Alıcı yorumları (parent_id boş) ve satıcının bu yorumlara cevabı (parent_id dolu). Alıcı yorumu silinince
  # bağlı satıcı cevabı veritabanı seviyesinde de silinir (ON DELETE CASCADE).
  def change
    create_table :comments do |t|
      t.references :product, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      # Her alıcı yorumuna en fazla bir satıcı cevabı: parent_id benzersiz.
      t.references :parent, null: true, index: { unique: true }, foreign_key: { to_table: :comments, on_delete: :cascade }
      t.text :body, null: false
      t.integer :likes_count, null: false, default: 0
      t.integer :dislikes_count, null: false, default: 0
      t.timestamps
    end
    # Ürün sayfası alıcı yorumlarını en yeniden eskiye sayfalar; yalnızca bu satırları kapsayan kısmi index.
    add_index :comments, [ :product_id, :created_at ], where: "parent_id IS NULL", name: "index_comments_on_product_top_level"
    add_check_constraint :comments, "char_length(body) BETWEEN 1 AND 2000", name: "comments_body_length"
    add_check_constraint :comments, "likes_count >= 0 AND dislikes_count >= 0", name: "comments_reaction_counts_nonnegative"
  end
end
