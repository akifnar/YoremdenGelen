class RemoveVisitMetricsAndLinkRatingsToComments < ActiveRecord::Migration[8.1]
  # Tıklanma ve üzerine gelme sayaçları kaldırıldı (kolayca şişirilebiliyordu).
  # Puan, verildiği ilk yoruma bağlanır: ürünün ortalaması o yorumun like/dislike'ına göre ağırlıklandırılır.
  # Yorum silinirse bağ kopar (ON DELETE SET NULL) ve puan ağırlık 1 ile sayılmaya devam eder.
  def up
    remove_check_constraint :product_metadata, name: "product_metadata_counters_nonnegative"
    remove_column :product_metadata, :click_count
    remove_column :product_metadata, :hover_count
    add_check_constraint :product_metadata, "rating_sum >= 0 AND rating_count >= 0 AND comment_count >= 0",
                         name: "product_metadata_counters_nonnegative"

    add_reference :product_purchases, :rating_comment, foreign_key: { to_table: :comments, on_delete: :nullify }
    execute <<~SQL
      UPDATE product_purchases pp
      SET rating_comment_id = (
        SELECT c.id FROM comments c
        WHERE c.user_id = pp.user_id AND c.product_id = pp.product_id AND c.parent_id IS NULL
        ORDER BY c.created_at, c.id LIMIT 1
      )
      WHERE pp.rating IS NOT NULL
    SQL
  end

  def down
    remove_reference :product_purchases, :rating_comment, foreign_key: { to_table: :comments }
    remove_check_constraint :product_metadata, name: "product_metadata_counters_nonnegative"
    add_column :product_metadata, :click_count, :bigint, null: false, default: 0
    add_column :product_metadata, :hover_count, :bigint, null: false, default: 0
    add_check_constraint :product_metadata,
                         "click_count >= 0 AND hover_count >= 0 AND rating_sum >= 0 AND rating_count >= 0 AND comment_count >= 0",
                         name: "product_metadata_counters_nonnegative"
  end
end
