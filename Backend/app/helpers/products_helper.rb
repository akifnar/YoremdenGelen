module ProductsHelper
  # Ürün görseli olmayan ürünler için yedek yemek fotoğrafları.
  REGIONAL_FOOD_PHOTOS = [
    "photo-1547592180-85f173990554",
    "photo-1546069901-ba9599a7e63c",
    "photo-1504674900247-0877df9cc836"
  ].freeze

  def category_anchor_id(category)
    "kategori-#{category.to_s.parameterize}"
  end

  def food_image_url(product_id, offset = 0)
    photo = REGIONAL_FOOD_PHOTOS[(product_id.to_i + offset).abs % REGIONAL_FOOD_PHOTOS.length]
    "https://images.unsplash.com/#{photo}?auto=format&fit=crop&w=900&q=80"
  end

  def product_image_url(product)
    product.main_image.attached? ? rails_blob_path(product.main_image, only_path: true) : food_image_url(product.id)
  end

  # Ana görsel + galeri; galeri boşsa yedek fotoğraflarla doldurulur (her zaman en az bir öğe döner).
  def product_photo_urls(product)
    gallery = product.gallery_images.map { |image| rails_blob_path(image, only_path: true) }
    gallery = [ 1, 2, 3 ].map { |offset| food_image_url(product.id, offset) } if gallery.empty?
    [ product_image_url(product), *gallery ]
  end
end
