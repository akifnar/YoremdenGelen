require "rails_helper"

# DB zorunlu: AddCartItemJob'ın yazdığı satırlar, adet birleştirme ve kullanıcıya göre sepet kapsamı test ediliyor.
RSpec.describe "Sepet", type: :request do
  include ActiveJob::TestHelper

  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:user) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
  let(:cart) { Cart.for(user) }
  let(:product) { Product.create!(name: "Kayseri Mantısı", description: "Yöresel mantı", category: "Hamur İşleri", price: 120, stock: 5) }

  before { sign_in_stubbed(user, stub_cart: false) }

  it "queues the addition, ignores unpermitted attributes and keeps repeated additions as separate lines" do
    expect do
      post cart_items_path, params: { product_id: product.id, quantity: 2, price: 0 }, headers: turbo_stream
    end.to have_enqueued_job(AddCartItemJob)
    expect(response).to have_http_status(:accepted)
    expect(response.body).to include(%(target="cart_badge"), "2 ürün", "cart-header-pulse")
    expect(cart.cart_items).to be_empty

    post cart_items_path, params: { product_id: product.id, quantity: 1 }, headers: turbo_stream
    perform_enqueued_jobs

    expect(cart.cart_items.pluck(:quantity)).to eq([ 2, 1 ])
    expect(cart.subtotal).to eq(360)
  end

  it "rejects a quantity larger than stock without enqueuing a job" do
    expect do
      post cart_items_path, params: { product_id: product.id, quantity: 6 }, headers: turbo_stream
    end.not_to have_enqueued_job(AddCartItemJob)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Stokta yalnızca 5 adet var")
  end

  it "updates the quantity and rejects invalid quantities" do
    item = cart.cart_items.create!(product: product, quantity: 1)

    patch cart_item_path(item), params: { quantity: 0 }, headers: turbo_stream
    expect(response).to have_http_status(:unprocessable_content)

    patch cart_item_path(item), params: { quantity: 3 }, headers: turbo_stream
    expect(item.reload.quantity).to eq(3)
    expect(response.body).to include(%(target="cart_contents"), "3 ürün")
  end

  it "removes a product from the cart" do
    item = cart.cart_items.create!(product: product, quantity: 1)

    delete cart_item_path(item), headers: turbo_stream

    expect(cart.cart_items.reload).to be_empty
    expect(response.body).to include("Sepetiniz henüz boş.")
  end

  it "shows current product fields instead of cart-time snapshots" do
    cart.cart_items.create!(product: product, quantity: 2)
    product.update!(name: "Güncel Mantı", price: 150, stock: 2)

    get cart_path

    expect(response.body).to include("Güncel Mantı", "₺300,00", "Güncel stok: 2")
  end

  it "does not expose another user's cart lines" do
    other_user = User.create!(name: "Diğer", email: "other@example.com", password: "secret123")
    other_item = Cart.for(other_user).cart_items.create!(product: product, quantity: 1)

    patch cart_item_path(other_item), params: { quantity: 3 }, headers: turbo_stream

    expect(response).to have_http_status(:not_found)
    expect(other_item.reload.quantity).to eq(1)
  end
end
