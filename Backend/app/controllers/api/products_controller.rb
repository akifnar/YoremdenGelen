class Api::ProductsController < ApplicationController
  skip_before_action :authenticate_request!
  include Pagy::Backend

  def index
    page = product_query_params[:page]
    active_products = Product.where(is_active: true)
    pagy, products = pagy(active_products.with_attached_main_image, limit: 10, page: page)
    image_revision = ActiveStorage::Attachment.where(record_type: "Product", name: "main_image").maximum(:created_at)
    fresh_when(etag: [ active_products.maximum(:updated_at), active_products.count, image_revision, pagy.page, 10 ], public: true)

    render json: {
      metadata: {
        current_page: pagy.page,
        next_page: pagy.next,
        prev_page: pagy.prev,
        total_pages: pagy.pages,
        total_count: pagy.count
      },
      data: products.map { |product| serialize_product(product) }
    }
  end


  def show
    slug = product_route_params[:slug]
    product = Product.where(is_active: true).with_attached_main_image.with_attached_gallery_images.find_by!(slug: slug)
    render json: serialize_product(product, include_gallery: true)
  end

  private

  def product_query_params
    permitted_params([ :page ])
  end

  def product_route_params
    permitted_params([ :slug ])
  end

  def serialize_product(product, include_gallery: false)
    serialized = {
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price.to_f,
      stock: product.stock,
      slug: product.slug,
      is_active: product.is_active,
      main_image_url: product.main_image.attached? ? url_for(product.main_image) : nil
    }
    serialized[:gallery_image_urls] = product.gallery_images.map { |image| url_for(image) } if include_gallery
    serialized
  end
end
