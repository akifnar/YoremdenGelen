class ProductMetadata < ApplicationRecord
  self.table_name = "product_metadata"

  belongs_to :product, inverse_of: :product_metadata

  validates :product_id, uniqueness: true
  validates :click_count, :hover_count, :rating_sum, :rating_count, :comment_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def record_click!
    increment!(:click_count)
  end

  def record_hover!
    increment!(:hover_count)
  end

  def record_rating!(stars)
    stars = Integer(stars)
    raise ArgumentError, "stars must be between 1 and 5" unless (1..5).cover?(stars)

    self.class.update_counters(id, rating_sum: stars, rating_count: 1)
    reload
  end

  def record_comment!
    increment!(:comment_count)
  end
end
