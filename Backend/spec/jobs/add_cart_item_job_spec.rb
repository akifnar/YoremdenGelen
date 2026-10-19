require "rails_helper"

RSpec.describe AddCartItemJob, type: :job do
  let(:cart) { Cart.for(User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123")) }
  let(:product) do
    Product.create!(name: "Test Mantı", description: "Yöresel mantı", category: "Hamur İşleri", price: 120, stock: 3, is_active: true)
  end

  it "adds the product to the cart" do
    expect { described_class.perform_now(cart.id, product.id, 2) }.to change(cart.cart_items, :count).by(1)
  end

  it "skips the addition when stock ran out before the job ran" do
    cart.cart_items.create!(product: product, quantity: 2)

    expect { described_class.perform_now(cart.id, product.id, 2) }.not_to change(CartItem, :count)
  end
end
