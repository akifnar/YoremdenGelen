require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:seller) { persisted_user(id: 91, role: "seller") }
  let(:buyer) { persisted_user(id: 92, role: "buyer") }
  let(:product) { preload_association(persisted_product(id: 93, seller_id: seller.id), :seller, seller) }

  describe "doğrulamalar (bellekte)" do
    it "lets only buyers who purchased the product write a comment" do
      allow(buyer).to receive(:purchase_of).with(product).and_return(nil)
      comment = Comment.new(product: product, user: buyer, body: "Harika")
      expect(comment).not_to be_valid
      expect(comment.errors[:base]).to include("Yorum yazmak için bu ürünü satın almış olmalısın")

      allow(buyer).to receive(:purchase_of).with(product).and_return(ProductPurchase.new)
      expect(comment).to be_valid
    end

    it "does not let sellers write top-level comments" do
      expect(Comment.new(product: product, user: seller, body: "Kendi ürünüm")).not_to be_valid
    end

    it "lets only the product's seller reply, and only to buyer comments" do
      parent = Comment.instantiate(Comment.column_defaults.merge("id" => 94, "product_id" => product.id, "user_id" => buyer.id, "body" => "x"))
      expect(Comment.new(product: product, user: seller, parent: parent, body: "Teşekkürler")).to be_valid

      other_seller = persisted_user(id: 95, role: "seller")
      expect(Comment.new(product: product, user: other_seller, parent: parent, body: "x")).not_to be_valid

      reply = Comment.instantiate(Comment.column_defaults.merge("id" => 96, "product_id" => product.id, "user_id" => seller.id, "parent_id" => 94, "body" => "x"))
      nested = Comment.new(product: product, user: seller, parent: reply, body: "x")
      expect(nested).not_to be_valid
      expect(nested.errors[:base]).to include("Yalnızca alıcı yorumlarına cevap yazılabilir")
    end

    it "requires a body of at most 2000 characters" do
      allow(buyer).to receive(:purchase_of).and_return(ProductPurchase.new)
      expect(Comment.new(product: product, user: buyer, body: "")).not_to be_valid
      expect(Comment.new(product: product, user: buyer, body: "a" * 2001)).not_to be_valid
    end
  end

  # DB zorunlu: cascade silme, benzersiz cevap index'i ve atomik yorum sayacı test ediliyor.
  describe "kalıcı davranış" do
    let(:seller) { User.create!(name: "Satıcı", email: "seller@example.com", password: "secret123", role: "seller") }
    let(:buyer) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
    let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 3, seller: seller) }
    let!(:purchase) { ProductPurchase.record!(user: buyer, product: product) }

    it "counts only buyer comments and removes the seller reply and reactions with the comment" do
      comment = product.comments.create!(user: buyer, body: "Harika")
      comment.create_reply!(product: product, user: seller, body: "Teşekkürler")
      other_buyer = User.create!(name: "Diğer", email: "other@example.com", password: "secret123")
      CommentReaction.toggle!(comment: comment, user: other_buyer, kind: "like")
      expect(product.metrics.reload.comment_count).to eq(1)

      comment.destroy!

      expect(Comment.count).to eq(0)
      expect(CommentReaction.count).to eq(0)
      expect(product.metrics.reload.comment_count).to eq(0)
    end

    it "keeps the rating when the rated first comment is deleted" do
      comment = product.comments.create!(user: buyer, body: "İlk yorum")
      purchase.rate!(5)

      comment.destroy!

      expect(purchase.reload.rating).to eq(5)
      expect(product.metrics.reload).to have_attributes(rating_sum: 5, rating_count: 1)
    end

    it "allows a single seller reply per buyer comment" do
      comment = product.comments.create!(user: buyer, body: "Harika")
      comment.create_reply!(product: product, user: seller, body: "Teşekkürler")

      second = Comment.new(product: product, user: seller, parent: comment, body: "Bir daha")
      expect(second).not_to be_valid
      expect { second.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
