require "rails_helper"

RSpec.describe "Api::Cart", type: :request do
  let(:cart_token) { SecureRandom.uuid }
  let(:headers) { { "X-Cart-Token" => cart_token } }
  let(:authenticated_user) { User.create!(name: "Cart User", email: "cart-user@example.com", password: "secret123") }
  let(:product) do
    Product.create!(name: "Test Kayseri Mantısı", description: "Yöresel mantı", category: "Hamur İşleri", price: 120, stock: 5, is_active: true)
  end

  before do
    session = authenticated_user.issue_session!
    cookies[:session_token] = session.fetch(:session_token)
  end

  describe "GET /api/cart" do
    it "returns an empty cart and creates it for the token" do
      get "/api/cart", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("token" => cart_token, "item_count" => 0, "items" => [])
    end

    it "requires a cart token" do
      get "/api/cart"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/cart/items" do
    it "adds a product to the cart and ignores unpermitted attributes" do
      post "/api/cart/items", params: { product_id: product.id, quantity: 2, price: 0 }, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("items", 0, "quantity")).to eq(2)
      expect(response.parsed_body.dig("items", 0, "product", "name")).to eq(product.name)
      expect(response.parsed_body.dig("items", 0, "product", "price")).to eq(120.0)
    end

    it "keeps repeated additions as separate cart lines" do
      2.times do
        post "/api/cart/items", params: { product_id: product.id, quantity: 1 }, headers: headers, as: :json
      end

      expect(response.parsed_body.fetch("items").length).to eq(2)
      expect(response.parsed_body.fetch("item_count")).to eq(2)
    end

    it "rejects a quantity larger than stock" do
      post "/api/cart/items", params: { product_id: product.id, quantity: 6 }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors").join).to include("Stokta yalnızca 5 adet var")
    end
  end

  describe "PATCH /api/cart/items/:id" do
    it "updates the quantity and rejects invalid quantities" do
      item = Cart.create!(token: cart_token).cart_items.create!(product: product, quantity: 1)
      patch "/api/cart/items/#{item.id}", params: { quantity: 0 }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      patch "/api/cart/items/#{item.id}", params: { quantity: 3 }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("items", 0, "quantity")).to eq(3)
    end
  end

  describe "DELETE /api/cart/items/:id" do
    it "removes a line from the cart" do
      item = Cart.create!(token: cart_token).cart_items.create!(product: product, quantity: 1)
      delete "/api/cart/items/#{item.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("items")).to be_empty
    end
  end

  it "serializes the current product fields instead of cart-time snapshots" do
    cart = Cart.create!(token: cart_token)
    cart.cart_items.create!(product: product, quantity: 2)
    product.update!(name: "Güncel Mantı", price: 150, stock: 2)

    get "/api/cart", headers: headers

    line = response.parsed_body.dig("items", 0)
    expect(line.dig("product", "name")).to eq("Güncel Mantı")
    expect(line.dig("product", "price")).to eq(150.0)
    expect(line.dig("product", "stock")).to eq(2)
    expect(line.fetch("line_total")).to eq(300.0)
  end
end
