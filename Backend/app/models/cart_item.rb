class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity,
            numericality: { only_integer: true, greater_than: 0, message: "Adet en az 1 olmalıdır" }
  validate :quantity_does_not_exceed_stock
  validate :product_is_active

  private

  def quantity_does_not_exceed_stock
    return unless cart && product && quantity.is_a?(Integer) && quantity.positive?

    other_items_quantity = cart.cart_items
                               .where(product_id: product.id)
                               .where.not(id: id)
                               .sum(:quantity)
    available_stock = [ product.stock - other_items_quantity, 0 ].max
    return unless quantity > available_stock

    errors.add(:quantity, "Stokta yalnızca #{available_stock} adet var")
  end

  def product_is_active
    return unless product && !product.is_active?

    errors.add(:product, "Satışta olmayan ürün sepete eklenemez")
  end
end
