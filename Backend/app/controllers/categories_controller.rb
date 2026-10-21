class CategoriesController < ApplicationController
  include CategoryPagination

  skip_before_action :authenticate_request!

  # Header menüsü ve anasayfa bölüm başlığından açılır (Turbo-Frame: main ya da tam sayfa):
  # yalnızca bu kategorinin ürünleri, 12'şer sayfalanır.
  def show
    @category = Product::CATEGORY_SLUGS[params[:slug].to_s]
    return render "pages/not_found", status: :not_found unless @category

    @pagy, @products = paginate_category(@category, page: requested_page)
  end
end
