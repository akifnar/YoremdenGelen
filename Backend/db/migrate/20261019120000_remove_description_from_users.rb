class RemoveDescriptionFromUsers < ActiveRecord::Migration[8.1]
  # Profil açıklaması kaldırıldı: alıcı yalnızca adını, satıcı adını ve profil resmini değiştirir.
  def up
    remove_check_constraint :users, name: "users_description_length_limit"
    remove_column :users, :description
  end

  def down
    add_column :users, :description, :text
    add_check_constraint :users, "char_length(description) <= 500", name: "users_description_length_limit"
  end
end
