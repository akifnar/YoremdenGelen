class CreateOrders < ActiveRecord::Migration[8.1]
  # Sepetten verilen sipariş (gerçek ödeme yok). Kalemler satın alma anındaki fiyatı saklar; ürün fiyatı sonradan
  # değişse de sipariş tutarı değişmez.
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :orders, "total >= 0", name: "orders_total_nonnegative"

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: { on_delete: :cascade }
      # Ürünler silinmez, yayından kaldırılır; sipariş geçmişindeki ürün silinemesin.
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "unit_price >= 0", name: "order_items_unit_price_nonnegative"
  end
end
