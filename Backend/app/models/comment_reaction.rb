# Bir alıcının bir yoruma tepkisi: like ya da dislike. Alıcı başına yorum başına tek satır (benzersiz index).
# Yalnızca yorumun ait olduğu ürünü satın almış alıcılar tepki verebilir.
class CommentReaction < ApplicationRecord
  KINDS = %w[like dislike].freeze

  belongs_to :comment
  belongs_to :user

  validates :kind, inclusion: { in: KINDS, message: "like ya da dislike olmalıdır" }
  validates :comment_id, uniqueness: { scope: :user_id }
  validate :reactor_rules

  # Aynı tepkiye tekrar basmak geri alır, diğerine basmak değiştirir, ilk basış ekler. Yorum satırı kilitlenir;
  # likes_count / dislikes_count aynı transaction içinde atomik olarak güncellenir.
  def self.toggle!(comment:, user:, kind:)
    transaction do
      comment.lock!
      existing = find_by(comment: comment, user: user)

      if existing&.kind == kind
        existing.destroy!
        Comment.update_counters(comment.id, counter_for(kind) => -1)
        nil
      elsif existing
        Comment.update_counters(comment.id, counter_for(existing.kind) => -1, counter_for(kind) => 1)
        existing.update!(kind: kind)
        existing
      else
        reaction = create!(comment: comment, user: user, kind: kind)
        Comment.update_counters(comment.id, counter_for(kind) => 1)
        reaction
      end
    end
  end

  def self.counter_for(kind)
    :"#{kind}s_count"
  end

  private

  def reactor_rules
    errors.add(:base, "Yalnızca alıcılar tepki verebilir") unless user&.buyer?
    errors.add(:base, "Kendi yorumuna tepki veremezsin") if comment && comment.user_id == user_id
    errors.add(:base, "Yalnızca alıcı yorumlarına tepki verilebilir") if comment&.reply?
    if user&.buyer? && comment && !user.purchase_of(comment.product)
      errors.add(:base, "Tepki vermek için bu ürünü satın almış olmalısın")
    end
  end
end
