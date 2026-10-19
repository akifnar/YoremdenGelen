require "rails_helper"

# DB zorunlu: satıcıya göre sorgu kapsamı (current_user.products), ActiveStorage eki ve arşivleme yazılıyor.
RSpec.describe "Satıcı ürünleri", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:seller) { User.create!(name: "Satıcı", email: "seller@example.com", password: "secret123", role: "seller") }
  let(:other_seller) { User.create!(name: "Diğer satıcı", email: "other@example.com", password: "secret123", role: "seller") }

  def create_product(owner, name)
    owner.products.create!(name: name, description: "x", category: "Peynir", price: 80, stock: 4)
  end

  before { sign_in_stubbed(seller) unless RSpec.current_example.metadata[:guest] }

  it "creates a product for the signed-in seller and ignores owner-controlled attributes" do
    image = Rack::Test::UploadedFile.new(StringIO.new("fake image"), "image/jpeg", original_filename: "main.jpg")

    post seller_products_path, headers: turbo_stream, params: {
      product: { main_image: image, name: "Balıkesir Lor Peyniri", description: "Günlük", category: "Peynir",
                 price: "180.50", stock: "12", seller_id: other_seller.id, is_active: false, sku: "FORGED-SKU" }
    }

    expect(response).to have_http_status(:created)
    product = Product.find_by!(name: "Balıkesir Lor Peyniri")
    expect(product).to have_attributes(seller: seller, is_active: true)
    expect(product.sku).not_to eq("FORGED-SKU")
    expect(response.body).to include(%(target="seller_products"), %(target="seller_products_empty"), "Ürün yayınlandı.")
  end

  it "only lists the current seller's products" do
    create_product(seller, "Benim Peynirim")
    create_product(other_seller, "Başkasının Zeytini")

    get seller_products_path

    expect(response.body).to include("Benim Peynirim")
    expect(response.body).not_to include("Başkasının Zeytini")
  end

  it "archives the seller's product instead of deleting it" do
    product = create_product(seller, "Mevsimlik Peynir")

    delete seller_product_path(product), headers: turbo_stream

    expect(product.reload.is_active).to be(false)
    expect(response.body).to include(%(target="product_#{product.id}"), "Yayından kaldırıldı")
  end

  it "edits a product inside the form frame and replaces its row" do
    product = create_product(seller, "Bergama Tulumu")

    get edit_seller_product_path(product)
    expect(response.body).to include(%(<turbo-frame id="seller_product_form">), "Ürünü düzenle")

    patch seller_product_path(product), params: { product: { stock: "7" } }, headers: turbo_stream
    expect(response.body).to include(%(target="product_#{product.id}"), "Stok: 7")
  end

  it "does not allow a seller to edit another seller's product" do
    product = create_product(other_seller, "Başkasının Zeytini")

    patch seller_product_path(product), params: { product: { price: "1" } }, headers: turbo_stream

    expect(response).to have_http_status(:not_found)
    expect(product.reload.price).to eq(80)
  end

  it "requires a session", :guest do
    get seller_products_path
    expect(response).to redirect_to(login_path(returnTo: "/satici/urunler"))
  end
end
