class SellersController < ApplicationController
  # requested_page ve Pagy::Backend için; satıcı sayfası da kategori sayfasıyla aynı sayfa boyunu kullanır.
  include CategoryPagination

  skip_before_action :authenticate_request!

  # Yayındaki tüm ürünler (tükenenler dahil) popülerliğe göre, 12'şer. Satıcı olmayan hesaplar 404 verir.
  def show
    @seller = User.where(role: "seller").find_by(id: params[:id])
    return render "pages/not_found", status: :not_found unless @seller

    scope = @seller.products.active
    @pagy, @products = pagy(scope.by_popularity.with_attached_main_image,
                            count: scope.count, limit: PAGE_PER_PAGE, page: requested_page)
  end
end
