require "rails_helper"

RSpec.describe "Api::Seller::Products", type: :request do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: "seller@example.com",
      password: "secret123",
      email_verified_at: Time.current
    )
  end

  before do
    post "/api/auth/login",
         params: { user: { email: seller.email, password: "secret123" } },
         as: :json
    expect(response).to have_http_status(:success)
  end

  it "creates a product for the signed-in seller and ignores owner-controlled attributes" do
    post "/api/seller/products",
         params: {
           product: {
             main_image: Rack::Test::UploadedFile.new(StringIO.new("fake image"), "image/jpeg", original_filename: "main.jpg"),
             name: "Balıkesir Lor Peyniri",
             description: "Günlük yerel peynir.",
             category: "Peynir",
             price: "180.50",
             stock: "12",
             seller_id: 999_999,
             is_active: false,
             sku: "FORGED-SKU"
           }
         },
         as: :multipart

    product = Product.find_by!(name: "Balıkesir Lor Peyniri")
    expect(response).to have_http_status(:created)
    expect(product.seller).to eq(seller)
    expect(product.is_active).to be(true)
    expect(product.sku).not_to eq("FORGED-SKU")
    expect(response.parsed_body).not_to have_key("sku")
  end

  it "only lists the current seller's products" do
    own_product = seller.products.create!(
      name: "Seller's cheese",
      description: "My product",
      category: "Peynir",
      price: 100,
      stock: 5
    )
    other_seller = User.create!(name: "Other seller", email: "other@example.com", password: "secret123")
    other_seller.products.create!(
      name: "Other seller's olive",
      description: "Another product",
      category: "Zeytin",
      price: 80,
      stock: 4
    )

    get "/api/seller/products"

    expect(response).to have_http_status(:success)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([ own_product.id ])
  end

  it "requires a main product image on the backend" do
    post "/api/seller/products",
         params: { product: { name: "Image required", description: "Product description", category: "Peynir", price: "20", stock: "2" } },
         as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to include("Ana ürün fotoğrafı zorunludur")
  end

  it "validates seller input on the backend" do
    post "/api/seller/products",
         params: {
           product: {
             name: "Invalid price product",
             description: "Must be rejected by server validation.",
             category: "Peynir",
             price: "0",
             stock: "2"
           }
         },
         as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to be_present
  end

  it "archives the seller's product without deleting cart references" do
    product = seller.products.create!(
      name: "Seasonal cheese",
      description: "Seasonal product",
      category: "Peynir",
      price: 90,
      stock: 2
    )

    delete "/api/seller/products/#{product.id}"

    expect(response).to have_http_status(:no_content)
    expect(product.reload.is_active).to be(false)
  end

  it "does not allow a seller to edit another seller's product" do
    other_seller = User.create!(name: "Other seller", email: "other@example.com", password: "secret123")
    product = other_seller.products.create!(
      name: "Other seller's olive",
      description: "Another product",
      category: "Zeytin",
      price: 80,
      stock: 4
    )

    patch "/api/seller/products/#{product.id}",
          params: { product: { price: 1 } },
          as: :json

    expect(response).to have_http_status(:not_found)
    expect(product.reload.price).to eq(80)
  end

  it "requires a session" do
    delete "/api/auth/logout"
    get "/api/seller/products"
    expect(response).to have_http_status(:unauthorized)
  end
end
