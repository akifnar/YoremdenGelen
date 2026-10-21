class AddDescriptionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :description, :text
    add_check_constraint :users, "char_length(description) <= 500", name: "users_description_length_limit"
  end
end
