require "rails_helper"

RSpec.describe Cart, type: :model do
  let(:user) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }

  it "gives each user exactly one cart" do
    cart = Cart.for(user)
    expect(Cart.for(user.reload)).to eq(cart)
    expect(Cart.new(user: user)).not_to be_valid
  end
end
