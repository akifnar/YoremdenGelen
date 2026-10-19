require "rails_helper"

# DB zorunlu: tek transaction içinde stok düşümü, sipariş kalemleri, yorum yetkisi ve geri alma test ediliyor.
RSpec.describe Checkout do
  let(:buyer) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
  let(:cart) { Cart.for(buyer) }
  let(:peynir) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 5) }
  let(:zeytin) { Product.create!(name: "Gemlik Zeytini", description: "x", category: "Zeytin", price: 40, stock: 2) }

  it "turns the cart into an order at current prices, lowers stock, grants comment rights and empties the cart" do
    2.times { cart.cart_items.create!(product: peynir, quantity: 1) }
    cart.cart_items.create!(product: zeytin, quantity: 2)

    order = Checkout.new(cart).place!

    expect(order.order_items.pluck(:product_id, :quantity, :unit_price)).to contain_exactly([ peynir.id, 2, 100 ], [ zeytin.id, 2, 40 ])
    expect(order.total).to eq(280)
    expect([ peynir.reload.stock, zeytin.reload.stock ]).to eq([ 3, 0 ])
    expect(buyer.purchase_of(peynir)).to be_present
    expect(buyer.purchase_of(zeytin)).to be_present
    expect(cart.cart_items.reload).to be_empty
  end

  it "keeps one purchase row when the same product is bought again" do
    cart.cart_items.create!(product: peynir, quantity: 1)
    Checkout.new(cart).place!
    cart.cart_items.create!(product: peynir, quantity: 1)

    expect { Checkout.new(cart).place! }.to change(Order, :count).by(1).and change(ProductPurchase, :count).by(0)
  end

  it "rolls everything back when stock ran out" do
    cart.cart_items.create!(product: peynir, quantity: 1)
    cart.cart_items.create!(product: zeytin, quantity: 2)
    zeytin.update!(stock: 1)

    expect { Checkout.new(cart).place! }.to raise_error(Checkout::Error, /stokta yalnızca 1 adet/)
    expect(Order.count).to eq(0)
    expect(ProductPurchase.count).to eq(0)
    expect(peynir.reload.stock).to eq(5)
    expect(cart.cart_items.count).to eq(2)
  end

  it "rejects an empty cart" do
    expect { Checkout.new(cart).place! }.to raise_error(Checkout::Error, "Sepetin boş")
  end
end
