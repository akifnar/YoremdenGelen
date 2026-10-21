class Seller::BaseController < ApplicationController
  before_action :require_seller!

  private

  def require_seller!
    require_role!("seller", message: "Bu alan yalnızca satıcılara açıktır")
  end
end
