class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :user_id, uniqueness: true

  # Kullanıcının sepeti; yoksa açılır. Eşzamanlı iki istek aynı anda açmaya çalışırsa ikincisi model
  # doğrulamasına (RecordInvalid) ya da unique index'e (RecordNotUnique) takılır ve var olan sepeti okur.
  def self.for(user)
    user.cart || user.create_cart!
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    user.reload_cart
  end

  def ordered_items
    cart_items.includes(product: { main_image_attachment: :blob }).order(:created_at, :id)
  end

  def item_count(items = ordered_items)
    items.sum(&:quantity)
  end

  def subtotal(items = ordered_items)
    items.sum { |item| item.quantity * item.product.price }
  end

  # Aynı ürün sepete birden çok satır olarak eklenebildiği için arayüz ürün bazında gruplar.
  def grouped_items(items = ordered_items)
    items.group_by(&:product_id).values
  end

  # Ürünün sepetteki toplam adedini tek satırda toplar; diğer satırlar silinir.
  # Önce kopyalar silinir ki stok doğrulaması yalnızca hedef adedi kontrol etsin.
  def set_product_quantity!(item, quantity)
    transaction do
      cart_items.where(product_id: item.product_id).where.not(id: item.id).delete_all
      item.update!(quantity: quantity)
    end
  end

  def remove_product!(item)
    cart_items.where(product_id: item.product_id).destroy_all
  end
end
