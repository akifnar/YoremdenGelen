require "rails_helper"

RSpec.describe CartItem, type: :model do
  let(:cart) { Cart.for(User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123")) }
  let(:product) do
    Product.create!(name: "Deneme Mantısı", description: "Açıklama", category: "Hamur İşleri", price: 100, stock: 3, is_active: true)
  end

  it "is valid for a positive quantity within stock" do
    expect(cart.cart_items.build(product: product, quantity: 2)).to be_valid
  end

  it "rejects zero and negative quantities" do
    [ 0, -1 ].each do |quantity|
      item = cart.cart_items.build(product: product, quantity: quantity)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to be_present
    end
  end

  it "rejects quantities above current stock" do
    item = cart.cart_items.build(product: product, quantity: 4)
    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to include("Stokta yalnızca 3 adet var")
  end

  it "validates the combined quantity across separate lines for the same product" do
    cart.cart_items.create!(product: product, quantity: 2)
    second_line = cart.cart_items.build(product: product, quantity: 2)

    expect(second_line).not_to be_valid
    expect(second_line.errors[:quantity]).to include("Stokta yalnızca 1 adet var")
  end

  it "rejects inactive products" do
    product.update!(is_active: false)
    item = cart.cart_items.build(product: product, quantity: 1)
    expect(item).not_to be_valid
    expect(item.errors[:product]).to include("Satışta olmayan ürün sepete eklenemez")
  end
end
