class BindCartsToUsers < ActiveRecord::Migration[8.1]
  def up
    # Token'lı sepetler hiçbir kullanıcıya eşlenemez (bağlantı yalnızca tarayıcı çerezindeydi); silinirler.
    execute "DELETE FROM cart_items"
    execute "DELETE FROM carts"
    remove_index :carts, :token
    remove_column :carts, :token
    # Her kullanıcının tek sepeti olur; unique index aynı anda iki sepet açılmasını da engeller.
    add_reference :carts, :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
  end

  def down
    remove_reference :carts, :user, foreign_key: true, index: true
    add_column :carts, :token, :string, null: false, default: -> { "gen_random_uuid()::text" }
    change_column_default :carts, :token, from: -> { "gen_random_uuid()::text" }, to: nil
    add_index :carts, :token, unique: true
  end
end
