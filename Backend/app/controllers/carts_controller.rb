class CartsController < CartBaseController
  def show
    @items = cart.ordered_items.to_a
  end
end
