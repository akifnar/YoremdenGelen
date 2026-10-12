class Product < ApplicationRecord
  belongs_to :seller, class_name: "User", inverse_of: :products, optional: true

  has_one_attached :main_image
  has_many_attached :gallery_images

  validates :name,
            presence: { message: "Ürün adı boş bırakılamaz" },
            uniqueness: { message: "Bu isimde bir ürün zaten mevcut, lütfen farklı bir isim deneyin" }

  validates :description, presence: { message: "Ürün açıklaması boş bırakılamaz" }

  validates :price, presence: { message: "Fiyat alanı zorunludur" },
                   numericality: { greater_than: 0, message: "Fiyat 0'dan büyük olmalıdır" }

  validates :stock, presence: { message: "Stok alanı zorunludur" },
                   numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "Stok adedi negatif olamaz" }

  validates :slug,
            presence: true,
            uniqueness: { message: "bu isimden türetilen URL zaten mevcut, lütfen ürün adını biraz değiştirin" }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    if name.present? && slug.blank?
      self.slug = name.parameterize
    end
  end
end
