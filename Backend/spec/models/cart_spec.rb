require "rails_helper"

RSpec.describe Cart, type: :model do
  it "generates a unique token when created" do
    cart = Cart.create!
    expect(cart.token).to match(/\A[0-9a-f-]{36}\z/i)
  end

  it "can contain multiple separate lines for the same product" do
    cart = Cart.create!
    product = Product.create!(name: "Deneme Yöresel Ürünü", description: "Açıklama", category: "Diğer Yöresel Ürünler", price: 25, stock: 5)

    2.times { cart.cart_items.create!(product: product, quantity: 1) }

    expect(cart.cart_items.count).to eq(2)
  end
end
