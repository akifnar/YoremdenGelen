class Api::Seller::ProductsController < ApplicationController
  def index
    products = current_user.products.with_attached_main_image.order(created_at: :desc)
    render json: { data: products.map { |product| serialize_seller_product(product) } }
  end

  def create
    attributes = seller_product_params
    unless attributes[:main_image].present?
      render json: { errors: [ "Ana ürün fotoğrafı zorunludur" ] }, status: :unprocessable_entity
      return
    end

    product = current_user.products.new(attributes)
    if product.save
      render json: serialize_seller_product(product), status: :created
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    product = current_user.products.find(seller_product_route_params[:id])
    if product.update(seller_product_params)
      render json: serialize_seller_product(product)
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Ürün bulunamadı" ] }, status: :not_found
  end

  def destroy
    product = current_user.products.find(seller_product_route_params[:id])
    product.update!(is_active: false)
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Ürün bulunamadı" ] }, status: :not_found
  end

  private

  def seller_product_params
    permitted_params(product: [ :name, :description, :category, :price, :stock, :main_image, { gallery_images: [] }])[:product] || ActionController::Parameters.new
  end

  def seller_product_route_params
    permitted_params([ :id ])
  end

  def serialize_seller_product(product)
    {
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
  end
end
