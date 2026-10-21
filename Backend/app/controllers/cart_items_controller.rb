class CartItemsController < CartBaseController
  before_action :load_cart_item, only: [ :update, :destroy ]

  # Ekleme AddCartItemJob ile arka planda yapılır. Turbo yanıtı rozeti beklenen adetle
  # hemen günceller; iş bitince job gerçek sepeti aynı Turbo Stream kanalına yayınlar.
  def create
    attributes = create_params
    product = Product.find(attributes.require(:product_id))
    item = CartItem.new(cart: cart, product: product, quantity: attributes.fetch(:quantity, 1))
    item.validate!

    AddCartItemJob.perform_later(cart.id, product.id, item.quantity)
    items = cart.ordered_items.to_a
    expected_item_count = cart.item_count(items) + item.quantity

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "cart_badge",
          partial: "carts/badge",
          locals: { cart: cart, items: items, pending_quantity: item.quantity, pending_subtotal: item.quantity * product.price }
        ), status: :accepted
      end
      format.html { redirect_back fallback_location: cart_path, notice: "#{product.name} sepetinize eklendi." }
    end
  end

  # Ürünün sepetteki toplam adedini ayarlar (aynı ürünün diğer satırları birleştirilir).
  def update
    cart.set_product_quantity!(@cart_item, update_params.require(:quantity))
    respond_with_cart
  end

  # Ürünü (tüm satırlarıyla) sepetten kaldırır.
  def destroy
    cart.remove_product!(@cart_item)
    respond_with_cart(notice: "#{@cart_item.product.name} sepetten kaldırıldı.")
  end

  private

  def respond_with_cart(notice: nil)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: cart_refresh_streams }
      format.html { redirect_to cart_path, notice: notice, status: :see_other }
    end
  end

  def load_cart_item
    @cart_item = cart.cart_items.find(item_id_params[:id])
  end

  def create_params
    permitted_params([ :product_id, :quantity ])
  end

  def update_params
    permitted_params([ :quantity ])
  end

  def item_id_params
    permitted_params([ :id ])
  end
end
