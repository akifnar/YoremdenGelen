class Product < ApplicationRecord
  CATEGORIES = [ "Peynir", "Zeytin", "Zeytinyağı", "Et ve Şarküteri", "Tatlılar", "Hamur İşleri", "Süt Ürünleri", "Diğer Yöresel Ürünler" ].freeze
  NAME_MAX_LENGTH = 120
  DESCRIPTION_MAX_LENGTH = 2_000
  belongs_to :seller, class_name: "User", inverse_of: :products, optional: true
  has_one :product_metadata, dependent: :destroy, inverse_of: :product

  has_one_attached :main_image
  has_many_attached :gallery_images

  validates :name,
            presence: { message: "Ürün adı boş bırakılamaz" },
            length: { maximum: NAME_MAX_LENGTH },
            uniqueness: { message: "Bu isimde bir ürün zaten mevcut, lütfen farklı bir isim deneyin" }

  validates :description, presence: { message: "Ürün açıklaması boş bırakılamaz" },
                          length: { maximum: DESCRIPTION_MAX_LENGTH }
  validates :category, presence: true, inclusion: { in: CATEGORIES }, length: { maximum: 40 }
  validates :sku, length: { maximum: 50 }, allow_nil: true
  validates :slug, length: { maximum: 140 }, allow_blank: true
  validates :price, numericality: { less_than_or_equal_to: 99_999_999.99 }, allow_nil: true
  validates :stock, numericality: { less_than_or_equal_to: 2_147_483_647 }, allow_nil: true


  validates :price, presence: { message: "Fiyat alanı zorunludur" },
                   numericality: { greater_than: 0, message: "Fiyat 0'dan büyük olmalıdır" }

  validates :stock, presence: { message: "Stok alanı zorunludur" },
                   numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "Stok adedi negatif olamaz" }

  validates :slug,
            presence: true,
            uniqueness: { message: "bu isimden türetilen URL zaten mevcut, lütfen ürün adını biraz değiştirin" }

  before_validation :generate_slug, on: :create
  after_create :ensure_product_metadata

  private

  def ensure_product_metadata
    create_product_metadata! unless product_metadata
  end


  def generate_slug
    if name.present? && slug.blank?
      self.slug = name.parameterize
    end
  end
end
