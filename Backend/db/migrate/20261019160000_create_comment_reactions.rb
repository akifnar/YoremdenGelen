class CreateCommentReactions < ActiveRecord::Migration[8.1]
  # Bir alıcının bir yoruma tek tepkisi olur (like ya da dislike); benzersiz index sayacın şişirilmesini engeller.
  def change
    create_table :comment_reactions do |t|
      t.references :comment, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.timestamps
    end
    add_index :comment_reactions, [ :comment_id, :user_id ], unique: true
    add_check_constraint :comment_reactions, "kind IN ('like', 'dislike')", name: "comment_reactions_kind_allowed"
  end
end
