class Api::CartsController < Api::CartBaseController
  def show
    render json: serialize_cart
  end
end
