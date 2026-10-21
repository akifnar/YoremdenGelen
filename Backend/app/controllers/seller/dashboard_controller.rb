class Seller::DashboardController < Seller::BaseController
  # Yayındaki ürünlerin ağırlıklı ortalama puanı, değerlendirme ve yorum sayıları. Ürün başına puanlar tek
  # GROUP BY sorgusuyla, genel ortalama tek sorguyla hesaplanır (Product.rating_stats_for / overall_rating_for).
  def show
    products = current_user.products.active.includes(:product_metadata).order(:name).to_a
    product_ids = products.map(&:id)
    stats = Product.rating_stats_for(product_ids)
    @rows = products.map do |product|
      rating = stats.fetch(product.id, { average: 0.0, count: 0 })
      { product: product, average_rating: rating[:average], rating_count: rating[:count],
        comment_count: product.product_metadata&.comment_count.to_i }
    end
    @totals = { rating_count: @rows.sum { |row| row[:rating_count] }, comment_count: @rows.sum { |row| row[:comment_count] } }
    @overall_rating = Product.overall_rating_for(product_ids)[:average]
  end
end
