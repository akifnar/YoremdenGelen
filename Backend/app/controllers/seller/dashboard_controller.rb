class Seller::DashboardController < Seller::BaseController
  METRICS = {
    click_count: "Tıklanma",
    hover_count: "Üzerine gelinme",
    rating_count: "Değerlendirme",
    comment_count: "Yorum"
  }.freeze

  def show
    products = current_user.products.active.includes(:product_metadata).order(:name).to_a
    @rows = products.map do |product|
      metadata = product.product_metadata || ProductMetadata.new
      [ *METRICS.keys, :rating_sum ].index_with { |metric| metadata.public_send(metric) }
                                    .merge(product: product, average_rating: metadata.average_rating)
    end
    @totals = METRICS.keys.index_with { |metric| @rows.sum { |row| row[metric] } }
    rating_sum = @rows.sum { |row| row[:rating_sum] }
    @overall_rating = @totals[:rating_count].zero? ? 0.0 : (rating_sum.to_f / @totals[:rating_count]).round(1)
  end
end
