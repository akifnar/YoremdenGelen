class Seller::ProductsController < Seller::BaseController
  before_action :load_products, only: :index
  before_action :find_product, only: [ :edit, :update, :destroy ]

  rescue_from ActiveRecord::RecordNotFound do
    respond_to do |format|
      format.turbo_stream { render turbo_stream: notice_stream("Ürün bulunamadı", error: true), status: :not_found }
      format.html { redirect_to seller_products_path, alert: "Ürün bulunamadı" }
    end
  end

  def index
    @product = current_user.products.new
  end

  def new
    @product = current_user.products.new
    render partial: "seller/products/form", locals: { product: @product }
  end

  def edit
    render partial: "seller/products/form", locals: { product: @product }
  end

  def create
    attributes = seller_product_params
    @product = current_user.products.new(attributes)
    return render_invalid unless valid_product_params?(attributes, require_main_image: true)

    if @product.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("seller_products_empty"),
            turbo_stream.prepend("seller_products", partial: "seller/products/product", locals: { product: @product }),
            turbo_stream.replace("seller_product_form", partial: "seller/products/form", locals: { product: current_user.products.new }),
            notice_stream("Ürün yayınlandı.")
          ], status: :created
        end
        format.html { redirect_to seller_products_path, notice: "Ürün yayınlandı." }
      end
    else
      render_invalid
    end
  end

  # Güncelleme sonrası satıcı listesinde yalnızca bu ürünün satırı replace edilir;
  # katalog/ürün sayfalarındaki kopyaları Product#broadcast_catalog_changes ile güncellenir.
  def update
    attributes = seller_product_params
    @product.assign_attributes(attributes)
    return render_invalid unless valid_product_params?(attributes)

    if @product.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@product, partial: "seller/products/product", locals: { product: @product }),
            turbo_stream.replace("seller_product_form", partial: "seller/products/form", locals: { product: current_user.products.new }),
            notice_stream("Ürün güncellendi.")
          ]
        end
        format.html { redirect_to seller_products_path, notice: "Ürün güncellendi.", status: :see_other }
      end
    else
      render_invalid
    end
  end

  def destroy
    @product.update!(is_active: false)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@product, partial: "seller/products/product", locals: { product: @product }),
          notice_stream("Ürün yayından kaldırıldı.")
        ]
      end
      format.html { redirect_to seller_products_path, notice: "Ürün yayından kaldırıldı.", status: :see_other }
    end
  end

  private

  def load_products
    @products = current_user.products.with_attached_main_image.order(created_at: :desc)
  end

  def find_product
    @product = current_user.products.find(seller_product_route_params[:id])
  end

  def render_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("seller_product_form", partial: "seller/products/form", locals: { product: @product }),
               status: :unprocessable_entity
      end
      format.html do
        load_products
        render :index, status: :unprocessable_entity
      end
    end
  end

  # Controller seviyesi doğrulama: biçimsel olarak hatalı istekler modele ulaşmadan reddedilir.
  # Aynı kurallar Product modelinde de (validates) bulunur; bu katman açık ve Türkçe hata mesajları
  # verir ve tip dönüşümünün ("abc" -> 0) hatayı gizlemesini engeller.
  def valid_product_params?(attributes, require_main_image: false)
    errors = []
    errors << "Ana ürün fotoğrafı zorunludur" if require_main_image && attributes[:main_image].blank?
    if attributes.key?(:category) && Product::CATEGORIES.exclude?(attributes[:category])
      errors << "Kategori listedeki seçeneklerden biri olmalıdır"
    end
    if attributes.key?(:price) && !attributes[:price].to_s.strip.match?(/\A\d+(\.\d{1,2})?\z/)
      errors << "Fiyat en fazla iki ondalık basamaklı pozitif bir sayı olmalıdır"
    end
    if attributes.key?(:stock) && !attributes[:stock].to_s.strip.match?(/\A\d+\z/)
      errors << "Stok adedi negatif olmayan bir tam sayı olmalıdır"
    end
    errors.each { |message| @product.errors.add(:base, message) }
    errors.empty?
  end

  def notice_stream(message, error: false)
    turbo_stream.append("notifications", partial: "shared/notice", locals: { message: message, error: error })
  end

  # Boş dosya alanları (HTML formu yeni fotoğraf seçilmeden gönderildiğinde) mevcut
  # Active Storage eklerini silmesin diye atılır.
  def seller_product_params
    attributes = permitted_params(product: [ :name, :description, :category, :price, :stock, :main_image, { gallery_images: [] } ])[:product] || ActionController::Parameters.new
    attributes.delete(:main_image) if attributes[:main_image].blank?
    attributes.delete(:gallery_images) if Array(attributes[:gallery_images]).compact_blank.empty?
    attributes
  end

  def seller_product_route_params
    permitted_params([ :id ])
  end
end
