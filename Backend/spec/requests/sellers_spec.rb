require "rails_helper"

# DB zorunlu: satıcının sayfasına hangi ürünlerin geldiği (yayında olanlar, tükenenler dahil) sorgu kapsamıyla belirleniyor.
RSpec.describe "Satıcı sayfası", type: :request do
  let(:seller) { User.create!(name: "Ayşe Üretici", email: "seller@example.com", password: "secret123", role: "seller") }

  def product(name, owner: seller, **attributes)
    Product.create!({ name: name, description: "x", category: "Peynir", price: 100, stock: 3, seller: owner }.merge(attributes))
  end

  it "shows the seller's profile and all active products, including sold-out ones" do
    product("Satışta Peynir")
    product("Tükenen Peynir", stock: 0)
    product("Arşiv Peynir", is_active: false)
    other = User.create!(name: "Diğer", email: "other@example.com", password: "secret123", role: "seller")
    product("Başkasının Peyniri", owner: other)

    get seller_path(seller)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ayşe Üretici", "2 ürün", "Satışta Peynir", "Tükenen Peynir", "Tükendi")
    expect(response.body).not_to include("Arşiv Peynir", "Başkasının Peyniri")
  end

  it "returns 404 for users who are not sellers" do
    buyer = User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123")

    get seller_path(buyer)

    expect(response).to have_http_status(:not_found)
  end
end
