class ProductsController < ApplicationController
  skip_before_action :authenticate_request!
  include ProductComments

  HOME_PER_CATEGORY = 4 # anasayfada her kategori bölümü tek sıra (4 ürün); sayfalama yok

  before_action :redirect_seller_to_dashboard, only: :index
  # Hover ölçümü misafirlere de açık; aynı istemcinin sayacı şişirmesi sınırlandırılır.
  rate_limit to: 60, within: 1.minute, only: :hover, with: -> { head :too_many_requests }

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
    @product.metrics.record_click! if countable_interaction?(@product)
    load_product_comments(@product)
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end

  # Katalog kartındaki ‹ › düğmeleri bu aksiyonu kartın Turbo Frame'i içinde çağırır;
  # yalnızca o ürünün fotoğrafı değişir, sayfanın geri kalanı yerinde kalır.
  def photo
    @product = find_active_product!
    photos = helpers.product_photo_urls(@product)
    @photo_index = product_query_params[:index].to_i % photos.length
    render partial: "products/card_photo", locals: { product: @product, photo_index: @photo_index }
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # Katalog kartı üzerinde imleç bekletildiğinde Stimulus (hover_metric_controller) bir kez çağırır.
  def hover
    product = find_active_product!
    product.metrics.record_hover! if countable_interaction?(product)
    head :no_content
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  # Satıcının kendi ürünündeki etkileşimleri ve Turbo'nun önden yüklemeleri (prefetch) sayılmaz.
  def countable_interaction?(product)
    return false if request.headers["X-Sec-Purpose"].to_s.include?("prefetch")

    current_user.nil? || product.seller_id != current_user.id
  end

  def redirect_seller_to_dashboard
    redirect_to seller_root_path if request.path == root_path && request.format.html? && current_user&.seller?
  end

  def find_active_product!
    Product.active.includes(:product_metadata, seller: { avatar_attachment: :blob }).with_attached_main_image.with_attached_gallery_images.find(product_route_params[:id])
  end

  def product_query_params
    permitted_params([ :index ])
  end

  def product_route_params
    permitted_params([ :id ])
  end
end
