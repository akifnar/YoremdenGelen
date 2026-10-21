# Sepeti siparişe çevirir (gerçek ödeme yok). Tek transaction içinde: ürünler kilitlenir, stok kontrol edilip
# düşülür, sipariş kalemleri satın alma anındaki fiyatla yazılır, her ürün için yorum yetkisi
# (ProductPurchase) kaydedilir ve sepet boşaltılır. Bir adım başarısız olursa hiçbiri kalıcı olmaz.
class Checkout
  class Error < StandardError; end

  def initialize(cart)
    @cart = cart
  end

  def place!
    lines = @cart.ordered_items.to_a.group_by(&:product_id)
    raise Error, "Sepetin boş" if lines.empty?

    Order.transaction do
      # SELECT ... FOR UPDATE: aynı ürünü aynı anda alan iki alıcı stoğu eksiye düşüremez.
      products = Product.where(id: lines.keys).order(:id).lock.index_by(&:id)
      order = @cart.user.orders.create!(total: 0)

      total = lines.sum do |product_id, items|
        product = products.fetch(product_id)
        quantity = items.sum(&:quantity)
        raise Error, "#{product.name} artık satışta değil" unless product.is_active?
        raise Error, "#{product.name} için stokta yalnızca #{product.stock} adet var" if quantity > product.stock

        order.order_items.create!(product: product, quantity: quantity, unit_price: product.price)
        product.update!(stock: product.stock - quantity)
        ProductPurchase.record!(user: @cart.user, product: product)
        quantity * product.price
      end

      order.update!(total: total)
      @cart.cart_items.delete_all
      order
    end
  end
end
