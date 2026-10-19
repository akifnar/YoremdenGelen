require "rails_helper"

# DB zorunlu: yorum, puan, cevap ve tepkilerin kalıcı etkileri (sayaçlar, cascade, yetki satırı) test ediliyor.
# Oturum mock'lanır (sign_in_stubbed): kullanıcılar gerçek, oturum token'ı DB'ye yazılmaz.
RSpec.describe "Yorumlar", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:seller) { User.create!(name: "Satıcı", email: "seller@example.com", password: "secret123", role: "seller") }
  let(:buyer) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
  let(:other_buyer) { User.create!(name: "Diğer Alıcı", email: "other@example.com", password: "secret123") }
  let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 5, seller: seller) }

  def purchase!(user = buyer)
    ProductPurchase.record!(user: user, product: product)
  end

  def post_comment(body: "Çok lezzetli", rating: nil)
    post product_comments_path(product), params: { comment: { body: body, rating: rating }.compact }, headers: turbo_stream
  end

  describe "yorum yazma" do
    it "shows no form and rejects comments from buyers who did not purchase the product" do
      sign_in_stubbed(buyer)

      get product_path(product)
      expect(response.body).not_to include('id="comment_form"')

      post_comment(rating: 5)
      expect(response).to have_http_status(:forbidden)
      expect(Comment.count).to eq(0)
    end

    it "requires stars on the first comment, records the rating once and hides the stars afterwards" do
      purchase!
      sign_in_stubbed(buyer)

      get product_path(product)
      expect(response.body).to include('id="comment_form"', 'class="star-input')

      post_comment
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("İlk yorumunda 1 ile 5 arasında yıldız seçmelisin")

      post_comment(rating: 4)
      expect(response).to have_http_status(:created)
      expect(response.body).to include(%(target="comments"), %(target="#{ActionView::RecordIdentifier.dom_id(product, :rating)}"), "4,0 · 1 değerlendirme")
      expect(response.body).not_to include('class="star-input')

      post_comment(body: "İkinci kez aldım, yine güzel", rating: 1)
      expect(response).to have_http_status(:created)
      expect(buyer.purchase_of(product).rating).to eq(4) # sonraki yorumların puanı yok sayılır
      expect(product.metrics.reload).to have_attributes(rating_count: 1, comment_count: 2)
    end

    it "validates the body in the controller" do
      purchase!
      sign_in_stubbed(buyer)

      post_comment(body: "   ", rating: 5)
      expect(response.body).to include("Yorum boş bırakılamaz")
      post_comment(body: "a" * 2001, rating: 5)
      expect(response.body).to include("Yorum en fazla 2000 karakter olabilir")
      expect(Comment.count).to eq(0)
    end

    it "does not let sellers write top-level comments" do
      sign_in_stubbed(seller)
      post_comment(rating: 5)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "silme" do
    let!(:comment) do
      purchase!
      product.comments.create!(user: buyer, body: "Harika").tap { |c| c.create_reply!(product: product, user: seller, body: "Teşekkürler") }
    end

    it "lets buyers delete only their own comments, removing the seller reply too" do
      sign_in_stubbed(other_buyer)
      delete comment_path(comment), headers: turbo_stream
      expect(response).to have_http_status(:forbidden)

      sign_in_stubbed(buyer)
      delete comment_path(comment), headers: turbo_stream
      expect(response.body).to include(%(action="remove"), %(target="comment_#{comment.id}"))
      expect(Comment.count).to eq(0)
    end

    it "does not let sellers delete comments or their replies" do
      sign_in_stubbed(seller)
      delete comment_path(comment.reply), headers: turbo_stream
      expect(response).to have_http_status(:forbidden)
      expect(Comment.count).to eq(2)
    end
  end

  describe "satıcı cevabı" do
    let!(:comment) do
      purchase!
      product.comments.create!(user: buyer, body: "Harika")
    end

    it "lets the product's seller reply once" do
      sign_in_stubbed(seller)

      get product_path(product)
      expect(response.body).to include(%(action="/yorumlar/#{comment.id}/cevap"))
      expect(response.body).not_to include('id="comment_form"')

      post comment_reply_path(comment), params: { reply: { body: "Teşekkür ederiz" } }, headers: turbo_stream
      expect(response.body).to include("Satıcının cevabı", "Teşekkür ederiz")

      post comment_reply_path(comment), params: { reply: { body: "Bir daha" } }, headers: turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Bu yoruma zaten cevap verdin")
      expect(comment.reload.reply.body).to eq("Teşekkür ederiz")
    end

    it "does not let other sellers reply" do
      other_seller = User.create!(name: "Başka Satıcı", email: "s2@example.com", password: "secret123", role: "seller")
      sign_in_stubbed(other_seller)

      post comment_reply_path(comment), params: { reply: { body: "x" } }, headers: turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect(comment.reload.reply).to be_nil
    end
  end

  describe "like / dislike" do
    let!(:comment) do
      purchase!
      product.comments.create!(user: buyer, body: "Harika")
    end

    it "lets other buyers toggle reactions" do
      sign_in_stubbed(other_buyer)

      post comment_reaction_path(comment), params: { kind: "like" }, headers: turbo_stream
      expect(response.body).to include(%(target="reactions_comment_#{comment.id}"), 'aria-pressed="true"')
      expect(comment.reload.likes_count).to eq(1)

      post comment_reaction_path(comment), params: { kind: "like" }, headers: turbo_stream
      expect(comment.reload.likes_count).to eq(0)
    end

    it "rejects sellers, reactions on one's own comment and unknown kinds" do
      sign_in_stubbed(seller)
      post comment_reaction_path(comment), params: { kind: "like" }, headers: turbo_stream
      expect(response).to have_http_status(:forbidden)

      sign_in_stubbed(buyer)
      post comment_reaction_path(comment), params: { kind: "dislike" }, headers: turbo_stream
      expect(response.body).to include("Kendi yorumuna tepki veremezsin")

      sign_in_stubbed(other_buyer)
      post comment_reaction_path(comment), params: { kind: "love" }, headers: turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
      expect(CommentReaction.count).to eq(0)
    end
  end

  it "pages comments inside their frame without counting a product click" do
    purchase!
    11.times { |index| product.comments.create!(user: buyer, body: "Yorum #{index}") }

    get product_comments_path(product, page: 2), headers: { "Turbo-Frame" => "product_comments" }

    expect(response.body).to include(%(<turbo-frame class="block" id="product_comments">), "Yorum 0")
    expect(product.metrics.reload.click_count).to eq(0)
  end

  it "grants comment rights after checkout" do
    sign_in_stubbed(buyer, stub_cart: false)
    Cart.for(buyer).cart_items.create!(product: product, quantity: 2)

    post cart_checkout_path

    expect(response).to redirect_to(cart_path)
    expect(flash[:notice]).to include("Siparişin alındı")
    expect(product.reload.stock).to eq(3)
    expect(buyer.purchase_of(product)).to be_present
  end
end
