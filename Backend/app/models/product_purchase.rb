# Alıcının bir ürünü satın almış olduğu bilgisi (yorum yazma yetkisi) ve ürüne verdiği tek puan.
# Her (alıcı, ürün) çifti için tek satır: ürün kaç kez alınırsa alınsın satır bir kez yazılır.
# Yorum yetkisi bu satırın varlığıdır; (user_id, product_id) benzersiz index'iyle tek sorguda bulunur.
# rating boşsa alıcı henüz puanlamamıştır. Puan yorumdan bağımsız, ayrı bir formla bir kez verilir.
class ProductPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :product
  # Alıcının ürüne yazdığı ilk yorum; ortalamadaki ağırlık bu yorumun like/dislike'ından gelir. Puan yorumdan önce
  # verildiyse ilk yorum yazılınca bağlanır (attach_rating_comment!). Yorum silinince boşalır.
  belongs_to :rating_comment, class_name: "Comment", optional: true

  validates :product_id, uniqueness: { scope: :user_id }
  validates :rating, inclusion: { in: 1..5, message: "1 ile 5 arasında olmalıdır" }, allow_nil: true
  validate :user_must_be_buyer, on: :create
  validate :rating_cannot_change, on: :update

  # Satın alma anında (Checkout) çağrılır; aynı ürünü ikinci kez alan alıcı için yeni satır açılmaz.
  # create_or_find_by! INSERT'ü savepoint içinde dener: eşzamanlı ikinci istek unique index'e takılırsa
  # dış transaction (sipariş) bozulmadan var olan satır okunur.
  def self.record!(user:, product:)
    find_by(user: user, product: product) || create_or_find_by!(user: user, product: product)
  end

  def rated?
    rating.present?
  end

  # Puan bir kez verilir (yorumlar düzenlenemediği gibi puan da değişmez); ürünün ortalaması aynı
  # transaction içinde güncellenir. with_lock satırı SELECT ... FOR UPDATE ile kilitleyip yeniden okur:
  # aynı alıcının eşzamanlı iki "ilk yorumu" puanı iki kez ortalamaya ekleyemez, ikincisi doğrulamaya takılır.
  def rate!(stars, comment: first_comment)
    with_lock do
      update!(rating: stars, rating_comment: comment)
      product.metrics.record_rating!(rating)
    end
  end

  # Yorumsuz verilmiş puanı alıcının ilk yorumuna bağlar; tek koşullu UPDATE, bağ zaten varsa hiçbir şey yapmaz.
  def attach_rating_comment!(comment)
    self.class.where(id: id, rating_comment_id: nil).where.not(rating: nil).update_all(rating_comment_id: comment.id)
  end

  private

  def first_comment
    product.comments.top_level.where(user_id: user_id).order(:created_at, :id).first
  end

  def user_must_be_buyer
    errors.add(:user, "alıcı olmalıdır") unless user&.buyer?
  end

  def rating_cannot_change
    errors.add(:rating, "bir kez verildikten sonra değiştirilemez") if rating_changed? && rating_was.present?
  end
end
