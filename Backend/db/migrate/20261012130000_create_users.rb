class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest
      t.string :role, null: false, default: "buyer"
      t.string :auth_token
      t.string :email_verification_token
      t.datetime :email_verification_expires_at
      t.datetime :email_verified_at
      t.string :google_uid
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :auth_token, unique: true
    add_index :users, :email_verification_token, unique: true
    add_index :users, :google_uid, unique: true
  end
end
