class CartBaseController < ApplicationController
  before_action :require_buyer!
  before_action :load_cart

  rescue_from ActiveRecord::RecordNotFound do
    cart_error("Sepet veya ürün bulunamadı", :not_found)
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    cart_error(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  private

  attr_reader :cart

  def require_buyer!
    require_role!("buyer", message: "Sepet yalnızca alıcı hesaplarına açıktır")
  end

  def load_cart
    @cart = current_cart
  end

  def cart_error(message, status)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notice", locals: { message: message, error: true }),
          *cart_refresh_streams
        ], status: status
      end
      format.html { redirect_back fallback_location: cart_path, alert: message }
    end
  end

  # Sepet sayfası ve header rozeti için Turbo Stream'ler (cart nil ise yalnızca hata gösterilir).
  def cart_refresh_streams
    return [] unless cart

    items = cart.ordered_items.to_a
    [
      turbo_stream.replace("cart_badge", partial: "carts/badge", locals: { cart: cart, items: items }),
      turbo_stream.replace("cart_contents", partial: "carts/contents", locals: { cart: cart, items: items })
    ]
  end
end
