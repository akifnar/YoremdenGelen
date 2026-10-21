# Alıcı yorumu (parent yok) ya da satıcının bir alıcı yorumuna cevabı (parent var).
# Yorumlar düzenlenemez; alıcı kendi yorumunu silebilir ve bağlı satıcı cevabı da silinir.
class Comment < ApplicationRecord
  BODY_MAX_LENGTH = 2_000

  belongs_to :product
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :reply
  has_one :reply, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :reactions, class_name: "CommentReaction", dependent: :delete_all

  scope :top_level, -> { where(parent_id: nil) }

  validates :body, presence: { message: "boş bırakılamaz" }, length: { maximum: BODY_MAX_LENGTH }
  validates :parent_id, uniqueness: { message: "bu yoruma zaten cevap verilmiş" }, allow_nil: true
  validate :buyer_comment_rules, unless: :reply?
  validate :seller_reply_rules, if: :reply?

  # Ürünün toplam yorum sayısı (ProductMetadata) yalnızca alıcı yorumlarını sayar.
  after_create :count_in_product_metrics, unless: :reply?
  after_destroy :uncount_in_product_metrics, unless: :reply?

  def reply?
    parent_id.present? || parent.present?
  end

  private

  def buyer_comment_rules
    return if user&.buyer? && user.purchase_of(product)

    errors.add(:base, "Yorum yazmak için bu ürünü satın almış olmalısın")
  end

  def seller_reply_rules
    errors.add(:base, "Yalnızca ürünün satıcısı cevap yazabilir") unless user&.seller? && product&.seller_id == user.id
    errors.add(:base, "Yalnızca alıcı yorumlarına cevap yazılabilir") if parent&.reply?
    errors.add(:base, "Cevap, yorumla aynı ürüne ait olmalıdır") if parent && parent.product_id != product_id
  end

  def count_in_product_metrics
    product.metrics.record_comment!
  end

  def uncount_in_product_metrics
    product.metrics.record_comment_removed!
  end
end
