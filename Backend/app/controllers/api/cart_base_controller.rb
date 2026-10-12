class Api::CartBaseController < ApplicationController
  before_action :load_cart

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Sepet veya ürün bulunamadı" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  attr_reader :cart

  def load_cart
    token = request.headers["X-Cart-Token"].to_s
    return render(json: { error: "X-Cart-Token başlığı gereklidir" }, status: :bad_request) if token.blank?

    @cart = Cart.find_or_create_by!(token: token)
  end

  def serialize_cart
    items = cart.cart_items.includes(:product).order(:created_at, :id)
    {
      token: cart.token,
      item_count: items.sum(&:quantity),
      subtotal: items.sum { |item| item.quantity * item.product.price }.to_f,
      items: items.map do |item|
        product = item.product
        {
          id: item.id,
          quantity: item.quantity,
          line_total: (item.quantity * product.price).to_f,
          product: {
            id: product.id,
            name: product.name,
            slug: product.slug,
            price: product.price.to_f,
            stock: product.stock,
            is_active: product.is_active,
            main_image_url: product.main_image.attached? ? url_for(product.main_image) : nil
          }
        }
      end
    }
  end
end
