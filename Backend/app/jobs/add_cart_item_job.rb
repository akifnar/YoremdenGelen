class AddCartItemJob < ApplicationJob
  queue_as :default

  def perform(cart_id, product_id, quantity)
    cart = Cart.find_by(id: cart_id)
    product = Product.find_by(id: product_id)
    return unless cart && product

    begin
      cart.cart_items.create!(product: product, quantity: quantity)
    rescue ActiveRecord::RecordInvalid => error
      Rails.logger.warn("AddCartItemJob skipped cart #{cart_id}: #{error.record.errors.full_messages.join(', ')}")
      broadcast_error(cart, "#{product.name} sepete eklenemedi: #{error.record.errors.full_messages.to_sentence}")
    end
    broadcast_cart(cart)
  end

  private

  # Sepet rozeti ve (açıksa) sepet sayfası, sayfa yenilenmeden Turbo Stream ile güncellenir.
  def broadcast_cart(cart)
    items = cart.ordered_items.to_a
    Turbo::StreamsChannel.broadcast_replace_to(cart, target: "cart_badge", partial: "carts/badge", locals: { cart: cart, items: items })
    Turbo::StreamsChannel.broadcast_replace_to(cart, target: "cart_contents", partial: "carts/contents", locals: { cart: cart, items: items })
  end

  def broadcast_error(cart, message)
    Turbo::StreamsChannel.broadcast_append_to(cart, target: "notifications", partial: "shared/notice", locals: { message: message, error: true })
  end
end
