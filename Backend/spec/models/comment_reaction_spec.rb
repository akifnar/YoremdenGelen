require "rails_helper"

# DB zorunlu: satır kilidi ve atomik like/dislike sayaçları test ediliyor.
RSpec.describe CommentReaction, type: :model do
  let(:author) { User.create!(name: "Yazar", email: "author@example.com", password: "secret123") }
  let(:reader) { User.create!(name: "Okur", email: "reader@example.com", password: "secret123") }
  let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 3) }
  let(:comment) do
    ProductPurchase.record!(user: author, product: product)
    product.comments.create!(user: author, body: "Harika")
  end

  def counts
    comment.reload.slice(:likes_count, :dislikes_count).values
  end

  it "adds, switches and removes a reaction while keeping the counters in sync" do
    ProductPurchase.record!(user: reader, product: product)
    CommentReaction.toggle!(comment: comment, user: reader, kind: "like")
    expect(counts).to eq([ 1, 0 ])

    CommentReaction.toggle!(comment: comment, user: reader, kind: "dislike")
    expect(counts).to eq([ 0, 1 ])

    expect(CommentReaction.toggle!(comment: comment, user: reader, kind: "dislike")).to be_nil
    expect(counts).to eq([ 0, 0 ])
    expect(CommentReaction.count).to eq(0)
  end

  it "accepts reactions only from buyers and not on their own comment" do
    seller = User.create!(name: "Satıcı", email: "seller@example.com", password: "secret123", role: "seller")
    expect { CommentReaction.toggle!(comment: comment, user: seller, kind: "like") }.to raise_error(ActiveRecord::RecordInvalid, /Yalnızca alıcılar/)
    expect { CommentReaction.toggle!(comment: comment, user: author, kind: "like") }.to raise_error(ActiveRecord::RecordInvalid, /Kendi yorumuna/)
    expect(counts).to eq([ 0, 0 ])
  end

  it "accepts reactions only from buyers who purchased the product" do
    expect { CommentReaction.toggle!(comment: comment, user: reader, kind: "like") }.to raise_error(ActiveRecord::RecordInvalid, /satın almış olmalısın/)

    ProductPurchase.record!(user: reader, product: product)
    CommentReaction.toggle!(comment: comment, user: reader, kind: "like")
    expect(counts).to eq([ 1, 0 ])
  end
end
