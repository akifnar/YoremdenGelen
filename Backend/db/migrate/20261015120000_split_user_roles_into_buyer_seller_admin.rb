class SplitUserRolesIntoBuyerSellerAdmin < ActiveRecord::Migration[8.1]
  def up
    # Ürünü olan mevcut kullanıcılar satıcı, diğerleri alıcı olur.
    execute <<~SQL
      UPDATE users SET role = 'seller'
      WHERE role = 'user' AND id IN (SELECT DISTINCT seller_id FROM products WHERE seller_id IS NOT NULL)
    SQL
    execute "UPDATE users SET role = 'buyer' WHERE role = 'user'"
    change_column_default :users, :role, from: "user", to: "buyer"
    add_check_constraint :users, "role IN ('buyer', 'seller', 'admin')", name: "users_role_allowed"
  end

  def down
    remove_check_constraint :users, name: "users_role_allowed"
    change_column_default :users, :role, from: "buyer", to: "user"
    execute "UPDATE users SET role = 'user' WHERE role IN ('buyer', 'seller')"
  end
end
