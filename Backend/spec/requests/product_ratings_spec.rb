require "rails_helper"

# DB zorunlu: puanın product_purchases'e ve ürün sayaçlarına yazılması, ilk yoruma bağlanması test ediliyor.
RSpec.describe "Ürün puanı", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:seller) { User.create!(name: "Satıcı", email: "seller@example.com", password: "secret123", role: "seller") }
  let(:buyer) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
  let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 5, seller: seller) }

  def rate(stars)
    post product_rating_path(product), params: { product_rating: { rating: stars } }, headers: turbo_stream
  end

  it "lets a buyer who purchased the product rate it once without writing a comment" do
    ProductPurchase.record!(user: buyer, product: product)
    sign_in_stubbed(buyer)

    rate(4)
    expect(response).to have_http_status(:created)
    expect(response.body).to include(%(action="remove" target="rating_form"), "4,0 · 1 değerlendirme")
    expect(buyer.purchase_of(product)).to have_attributes(rating: 4, rating_comment_id: nil)
    expect(product.metrics.reload).to have_attributes(rating_sum: 4, rating_count: 1, comment_count: 0)

    get product_path(product)
    expect(response.body).not_to include('id="rating_form"')

    rate(1)
    expect(response).to have_http_status(:unprocessable_content)
    expect(buyer.purchase_of(product).rating).to eq(4)
  end

  it "requires 1 to 5 stars" do
    ProductPurchase.record!(user: buyer, product: product)
    sign_in_stubbed(buyer)

    rate(nil)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("1 ile 5 arasında yıldız seçmelisin")
    expect(buyer.purchase_of(product)).not_to be_rated
  end

  it "rejects buyers who did not purchase the product and sellers" do
    sign_in_stubbed(buyer)
    rate(5)
    expect(response).to have_http_status(:forbidden)

    sign_in_stubbed(seller)
    rate(5)
    expect(response).to have_http_status(:forbidden)
    expect(ProductPurchase.where.not(rating: nil)).to be_empty
  end

  it "links the rating to the buyer's first comment, whether written before or after rating" do
    purchase = ProductPurchase.record!(user: buyer, product: product)
    sign_in_stubbed(buyer)

    rate(5)
    post product_comments_path(product), params: { comment: { body: "İlk yorum" } }, headers: turbo_stream
    first = Comment.last
    post product_comments_path(product), params: { comment: { body: "İkinci yorum" } }, headers: turbo_stream
    expect(purchase.reload.rating_comment).to eq(first)

    other = User.create!(name: "Diğer", email: "other@example.com", password: "secret123")
    other_purchase = ProductPurchase.record!(user: other, product: product)
    earlier = product.comments.create!(user: other, body: "Önce yorum")
    other_purchase.rate!(3)
    expect(other_purchase.reload.rating_comment).to eq(earlier)
  end
end
