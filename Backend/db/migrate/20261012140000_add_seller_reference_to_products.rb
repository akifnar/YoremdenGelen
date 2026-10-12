class AddSellerReferenceToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :seller, foreign_key: { to_table: :users }, index: true, null: true
  end
end
