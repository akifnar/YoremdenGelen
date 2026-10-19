class Product < ApplicationRecord
  CATEGORIES = [ "Peynir", "Zeytin", "Zeytinyağı", "Et ve Şarküteri", "Tatlılar", "Hamur İşleri", "Süt Ürünleri", "Diğer Yöresel Ürünler" ].freeze
  NAME_MAX_LENGTH = 120
  DESCRIPTION_MAX_LENGTH = 2_000
  belongs_to :seller, class_name: "User", inverse_of: :products, optional: true
  has_one :product_metadata, dependent: :destroy, inverse_of: :product
  has_many :product_purchases, dependent: :destroy
  has_many :comments, dependent: :destroy

  has_one_attached :main_image
  has_many_attached :gallery_images

  # URL'lerde kategori adı yerine slug kullanılır: "Zeytinyağı" -> "zeytinyagi".
  CATEGORY_SLUGS = CATEGORIES.index_by(&:parameterize).freeze

  # Birleşik popülerlik skoru (ProductMetadata sayaçları). Tıklanma (ürün sayfası açılması) ana sinyal;
  # yorum ve yıldızlar daha güçlü ilgi gösterdiği için ağırlıklı, hover zayıf sinyal olduğu için 1/10 sayılır.
  # rating_sum kullanıldığı için çok oy alan ve yüksek puanlı ürün öne çıkar (tek 5 yıldız = 10 tıklanma).
  POPULARITY_SCORE_SQL = <<~SQL.squish.freeze
    COALESCE(product_metadata.click_count, 0)
    + COALESCE(product_metadata.comment_count, 0) * 5
    + COALESCE(product_metadata.rating_sum, 0) * 2
    + COALESCE(product_metadata.hover_count, 0) / 10
  SQL

  scope :active, -> { where(is_active: true) }
  scope :available, -> { active.where("stock > 0") }
  # Eşit skorda id ile sıralanır; sayfalar arasında aynı ürün iki kez görünmez veya kaybolmaz.
  scope :by_popularity, -> { left_joins(:product_metadata).order(Arel.sql("#{POPULARITY_SCORE_SQL} DESC"), :id) }

  def self.category_slug(category)
    category.to_s.parameterize
  end

  validates :name,
            presence: { message: "Ürün adı boş bırakılamaz" },
            length: { maximum: NAME_MAX_LENGTH },
            uniqueness: { message: "Bu isimde bir ürün zaten mevcut, lütfen farklı bir isim deneyin" }

  validates :description, presence: { message: "Ürün açıklaması boş bırakılamaz" },
                          length: { maximum: DESCRIPTION_MAX_LENGTH }
  validates :category, presence: true, inclusion: { in: CATEGORIES }, length: { maximum: 40 }
  validates :sku, length: { maximum: 50 }, allow_nil: true
  validates :price, numericality: { less_than_or_equal_to: 99_999_999.99 }, allow_nil: true
  validates :stock, numericality: { less_than_or_equal_to: 2_147_483_647 }, allow_nil: true


  validates :price, presence: { message: "Fiyat alanı zorunludur" },
                   numericality: { greater_than: 0, message: "Fiyat 0'dan büyük olmalıdır" }

  validates :stock, presence: { message: "Stok alanı zorunludur" },
                   numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "Stok adedi negatif olamaz" }

  validate :seller_must_have_seller_role, if: -> { seller && (new_record? || will_save_change_to_seller_id?) }

  after_create :ensure_product_metadata
  after_update_commit :broadcast_catalog_changes

  def available?
    is_active? && stock.to_i.positive?
  end

  # Metadata kaydı olmayan eski ürünler için kayıt ilk erişimde oluşturulur.
  def metrics
    product_metadata || create_product_metadata!
  end

  private

  def seller_must_have_seller_role
    errors.add(:seller, "satıcı rolüne sahip olmalıdır") unless seller.seller?
  end

  # Açık olan katalog/ürün sayfalarında yalnızca bu ürünün DOM parçalarını Turbo Stream ile değiştirir;
  # sayfa yenilenmez. Satıştan çıkan/tükenen ürün katalogdan kaldırılır.
  def broadcast_catalog_changes
    if available?
      broadcast_replace_to :products, target: dom_id_for(:card), partial: "products/card", locals: { product: self }
    else
      broadcast_remove_to :products, target: dom_id_for(:card)
    end
    broadcast_replace_to self, target: dom_id_for(:details), partial: "products/details", locals: { product: self }
  end

  def dom_id_for(prefix)
    ActionView::RecordIdentifier.dom_id(self, prefix)
  end

  def ensure_product_metadata
    create_product_metadata! unless product_metadata
  end
end
