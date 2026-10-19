class CategoriesController < ApplicationController
  include CategoryPagination

  skip_before_action :authenticate_request!

  # İki kullanım:
  # - Anasayfadaki kategori bölümünün sayfa bağlantıları (Turbo-Frame: category_<slug>): yalnızca o bölüm,
  #   6'şar ürünle yeniden render edilir; diğer kategoriler yerinde kalır.
  # - Header menüsü ve bölüm başlığı (Turbo-Frame: main ya da tam sayfa): yalnızca bu kategorinin ürünleri, 12'şer.
  def show
    @category = Product::CATEGORY_SLUGS[params[:slug].to_s]
    return render "pages/not_found", status: :not_found unless @category

    if turbo_frame_request_id == "category_#{params[:slug]}"
      pagy, products = paginate_category(@category, page: requested_page)
      render partial: "categories/section", locals: { category: @category, pagy: pagy, products: products }
    else
      @pagy, @products = paginate_category(@category, page: requested_page, limit: PAGE_PER_PAGE)
    end
  end
end
