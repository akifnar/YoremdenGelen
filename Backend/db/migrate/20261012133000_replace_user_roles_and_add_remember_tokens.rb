class ReplaceUserRolesAndAddRememberTokens < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET role = 'user' WHERE role IN ('buyer', 'seller')"
    change_column_default :users, :role, from: "buyer", to: "user"
    rename_column :users, :auth_token, :session_token
    if index_exists?(:users, :session_token, unique: true) && !index_name_exists?(:users, :index_users_on_session_token)
      remove_index :users, :session_token
    end
    add_index :users, :session_token, unique: true unless index_exists?(:users, :session_token, unique: true)
    add_column :users, :session_token_expires_at, :datetime
    add_column :users, :remember_token, :string
    add_column :users, :remember_token_expires_at, :datetime
    execute "UPDATE users SET session_token = NULL"
    add_index :users, :remember_token, unique: true
  end

  def down
    remove_index :users, :remember_token
    remove_column :users, :remember_token_expires_at
    remove_column :users, :remember_token
    remove_column :users, :session_token_expires_at
    remove_index :users, :session_token, if_exists: true
    rename_column :users, :session_token, :auth_token
    add_index :users, :auth_token, unique: true unless index_exists?(:users, :auth_token, unique: true)
    change_column_default :users, :role, from: "user", to: "buyer"
    execute "UPDATE users SET role = 'buyer' WHERE role = 'user'"
  end
end
