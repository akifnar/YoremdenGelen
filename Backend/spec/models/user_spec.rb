require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes email and only allows buyer, seller and admin roles" do
    user = described_class.new(name: "Test", email: " TEST@example.com ", role: "buyer", password: "secret123")
    expect(user).to be_valid
    expect(user.email).to eq("test@example.com")
    user.role = "owner"
    expect(user).not_to be_valid
  end

  it "has many products through the seller association" do
    user = described_class.create!(name: "Seller", email: "seller@example.com", password: "secret123", role: "seller")
    product = Product.create!(
      name: "Local olive oil",
      description: "Made by the user",
      price: 90,
      stock: 3,
      category: "Zeytinyağı",
      seller: user
    )
    product.main_image.attach(io: StringIO.new("test image"), filename: "test.jpg", content_type: "image/jpeg")
    product.save!

    expect(user.products).to contain_exactly(product)
  end

  it "allows short passwords only for explicitly seeded accounts" do
    user = described_class.new(name: "Seed User", email: "seed@example.com", password: "user")
    expect(user).not_to be_valid

    user.allow_seed_password = true
    expect(user).to be_valid
  end

  it "hashes passwords with bcrypt and compares hashes on authenticate" do
    user = described_class.new(name: "Test", email: "test@example.com", password: "secret123")
    expect(BCrypt::Password.valid_hash?(user.password_digest)).to be(true)
    expect(BCrypt::Password.new(user.password_digest).is_password?("secret123")).to be(true)
    expect(user.authenticate("secret123")).to eq(user)
    expect(user.authenticate("wrongpass")).to be(false)
    expect(user.password_digest).not_to include("secret123")
  end

  it "issues a short session token and a rotating remember token" do
    user = described_class.create!(name: "Test", email: "tokens@example.com", password: "secret123")
    issued_tokens = user.issue_session!(remember_me: true)
    first_remember_token = issued_tokens.fetch(:remember_token)

    expect(user.session_token_expires_at).to be_within(1.second).of(User::SESSION_IDLE_TIMEOUT.from_now)
    expect(user.remember_token_expires_at).to be_within(1.second).of(30.days.from_now)
    expect(user.session_token).to eq(described_class.token_digest(issued_tokens.fetch(:session_token)))
    # DB yalnızca özetleri tutar; ham token'lar (cookie'ye giden) veritabanında yer almaz.
    expect(user.remember_token).to eq(described_class.token_digest(first_remember_token))
    expect(user.remember_token).not_to eq(first_remember_token)
    expect(user.refresh_session!("yanlis-token")).to be(false)
    refreshed_tokens = user.refresh_session!(first_remember_token)
    expect(refreshed_tokens).to be_a(Hash)
    expect(user.reload.remember_token).to eq(described_class.token_digest(refreshed_tokens.fetch(:remember_token)))
    expect(user.refresh_session!(first_remember_token)).to be(false)
    expect(user.revoke_tokens!).to be(true)
    expect(user.reload.session_token).to be_nil
  end

  it "expires email verification links after ten minutes" do
    user = described_class.create!(name: "Test", email: "test@example.com", password: "secret123")
    user.issue_email_verification!
    token = user.email_verification_token
    expect(user.email_verification_expires_at).to be_within(1.second).of(10.minutes.from_now)
    travel_to(11.minutes.from_now) do
      expect(user.verify_email!(token)).to be(false)
      expect(user.reload.email_verified_at).to be_nil
    end
  end
end
