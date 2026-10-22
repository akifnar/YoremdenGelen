class ProductsController < ApplicationController
  skip_before_action :authenticate_request!
  include ProductComments

  HOME_PER_CATEGORY = 4 # anasayfada her kategori bölümü tek sıra (4 ürün); sayfalama yok

  before_action :redirect_seller_to_dashboard, only: :index

  def index
    response.headers["Cache-Control"] = "no-store"

    # Her kategorinin ürün sayısı tek GROUP BY sorgusuyla alınır; boş kategoriler hiç sorgulanmaz.
    # Bölümde en popüler 4 ürün gösterilir, devamı "Tümünü gör" ile kategori sayfasında.
    counts = Product.available.group(:category).count
    @category_sections = Product::CATEGORIES.filter_map do |category|
      next unless counts[category].to_i.positive?

      products = Product.available.where(category: category).by_popularity.with_attached_main_image.limit(HOME_PER_CATEGORY)
      [ category, counts[category], products ]
    end
  end

  def show
    @product = find_active_product!
    load_product_comments(@product)
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end

  private

  def redirect_seller_to_dashboard
    redirect_to seller_root_path if request.path == root_path && request.format.html? && current_user&.seller?
  end

  def find_active_product!
    Product.active.includes(:product_metadata, seller: { avatar_attachment: :blob }).with_attached_main_image.with_attached_gallery_images.find(product_route_params[:id])
  end

  def product_route_params
    permitted_params([ :id ])
  end
end
