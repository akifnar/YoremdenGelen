class ProductMetadata < ApplicationRecord
  self.table_name = "product_metadata"

  belongs_to :product, inverse_of: :product_metadata

  validates :product_id, uniqueness: true
  validates :rating_sum, :rating_count, :comment_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def record_rating!(stars)
    stars = Integer(stars)
    raise ArgumentError, "stars must be between 1 and 5" unless (1..5).cover?(stars)

    self.class.update_counters(id, rating_sum: stars, rating_count: 1)
    reload
  end

  def record_comment!
    increment!(:comment_count)
  end

  def record_comment_removed!
    decrement!(:comment_count)
  end
end
