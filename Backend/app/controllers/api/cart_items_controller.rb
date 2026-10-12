class Api::CartItemsController < Api::CartBaseController
  before_action :load_cart_item, only: [ :update, :destroy ]

  def create
    attributes = create_params
    product = Product.find(attributes.require(:product_id))
    item = cart.cart_items.build(product: product, quantity: attributes.fetch(:quantity, 1))
    item.save!
    render json: serialize_cart, status: :created
  end

  def update
    @cart_item.update!(quantity: update_params.require(:quantity))
    render json: serialize_cart
  end

  def destroy
    @cart_item.destroy!
    render json: serialize_cart
  end

  private

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
