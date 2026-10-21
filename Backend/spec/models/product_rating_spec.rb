require "rails_helper"

# Ağırlıklı ortalama puan: ağırlık = (1 + like) / (1 + dislike), puanın verildiği ilk yorumun tepkilerinden.
# DB zorunlu: test edilen şey ağırlıklı ortalamayı hesaplayan SQL (JOIN + GROUP BY).
RSpec.describe Product, "ağırlıklı puan", type: :model do
  let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 9) }
  # Tepki vermek için ürünü satın almış olmak gerekir (CommentReaction#reactor_rules).
  let(:voters) do
    Array.new(4) do |index|
      User.create!(name: "Oy #{index}", email: "oy#{index}@example.com", password: "secret123")
          .tap { |voter| ProductPurchase.record!(user: voter, product: product) }
    end
  end

  # Alıcı ürünü alır, ilk yorumunu puanla yazar; diğer alıcılar o yoruma tepki verir.
  def rate(stars, likes: 0, dislikes: 0)
    buyer = User.create!(name: "Alıcı #{stars}", email: "alici#{stars}-#{SecureRandom.hex(3)}@example.com", password: "secret123")
    purchase = ProductPurchase.record!(user: buyer, product: product)
    comment = product.comments.create!(user: buyer, body: "#{stars} yıldız")
    purchase.rate!(stars, comment: comment)
    voters.first(likes).each { |voter| CommentReaction.toggle!(comment: comment, user: voter, kind: "like") }
    voters.last(dislikes).each { |voter| CommentReaction.toggle!(comment: comment, user: voter, kind: "dislike") }
    comment
  end

  it "is empty without ratings" do
    expect(product.rating_stats).to eq(average: 0.0, count: 0)
  end

  it "weights each rating by the likes and dislikes of its comment" do
    rate(5, likes: 4)      # ağırlık 5
    rate(2, dislikes: 3)   # ağırlık 0,25
    rate(4)                # ağırlık 1

    # (25 + 0,5 + 4) / (5 + 0,25 + 1) = 4,72 → 4,7 (düz ortalama 3,7 olurdu)
    expect(product.rating_stats).to eq(average: 4.7, count: 3)
  end

  it "keeps a rating with weight 1 after its comment is deleted" do
    liked = rate(5, likes: 4)
    rate(2, dislikes: 3)
    rate(4)

    liked.destroy!

    # (5 + 0,5 + 4) / (1 + 0,25 + 1) = 4,22 → 4,2
    expect(product.rating_stats).to eq(average: 4.2, count: 3)
  end

  it "computes per-product and overall averages for several products in single queries" do
    other = Product.create!(name: "Tulum Peyniri", description: "x", category: "Peynir", price: 100, stock: 9)
    rate(5, likes: 1)   # ağırlık 2
    rate(3)             # ağırlık 1
    buyer = User.create!(name: "Diğer", email: "diger@example.com", password: "secret123")
    ProductPurchase.record!(user: buyer, product: other).rate!(1, comment: nil)

    stats = Product.rating_stats_for([ product.id, other.id ])
    expect(stats).to eq(product.id => { average: 4.3, count: 2 }, other.id => { average: 1.0, count: 1 })
    # (10 + 3 + 1) / (2 + 1 + 1) = 3,5
    expect(Product.overall_rating_for([ product.id, other.id ])).to eq(average: 3.5, count: 3)
  end
end
