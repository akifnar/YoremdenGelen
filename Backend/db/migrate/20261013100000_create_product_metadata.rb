class CreateProductMetadata < ActiveRecord::Migration[8.1]
  def up
    create_table :product_metadata do |t|
      t.references :product, null: true, foreign_key: true, index: { unique: true }
      t.bigint :click_count, null: false, default: 0
      t.bigint :hover_count, null: false, default: 0
      t.bigint :rating_sum, null: false, default: 0
      t.bigint :rating_count, null: false, default: 0
      t.bigint :comment_count, null: false, default: 0
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO product_metadata (product_id, created_at, updated_at)
      SELECT id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM products
    SQL

    change_column_null :product_metadata, :product_id, false
    add_check_constraint :product_metadata,
                         "click_count >= 0 AND hover_count >= 0 AND rating_sum >= 0 AND rating_count >= 0 AND comment_count >= 0",
                         name: "product_metadata_counters_nonnegative"
  end

  def down
    drop_table :product_metadata
  end
end
