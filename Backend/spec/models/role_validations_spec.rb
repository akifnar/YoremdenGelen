require "rails_helper"

# Kayıtlar bellekte kurulur (InMemoryRecords); yalnızca doğrulamanın kendisi DB'ye bağlıysa gerçek kayıt yazılır.
RSpec.describe "Rol ve ürün sahipliği model doğrulamaları", type: :model do
  def product_attributes(overrides = {})
    { name: "Ezine Peyniri", description: "Tam yağlı", category: "Peynir", price: 150, stock: 4 }.merge(overrides)
  end

  describe User do
    it "defaults new users to the buyer role" do
      user = User.new
      expect(user.role).to eq("buyer")
      expect(user).to be_buyer
      expect(user).not_to be_seller
      expect(user).not_to be_admin
    end

    it "rejects roles outside buyer, seller and admin" do
      user = User.new(name: "X", email: "x@example.com", password: "secret123", role: "user")
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("geçerli bir rol değil")
    end

    # DB zorunlu: test edilen şey veritabanındaki check constraint.
    it "is protected by a database check constraint as well" do
      user = User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123")
      expect { user.update_column(:role, "superuser") }.to raise_error(ActiveRecord::StatementInvalid, /users_role_allowed/)
    end

    it "does not let a seller with active products lose the seller role" do
      seller = persisted_user(role: "seller")
      active_products = double("active products", exists?: true)
      allow(seller).to receive(:products).and_return(double("products", active: active_products))

      seller.role = "buyer"
      expect(seller).not_to be_valid
      expect(seller.errors[:role].first).to include("yayında ürünü olan satıcı")

      allow(active_products).to receive(:exists?).and_return(false)
      expect(seller).to be_valid
    end

    it "skips the product check when the role does not change" do
      seller = persisted_user(role: "seller", name: "Eski ad")
      expect(seller).not_to receive(:products)

      seller.name = "Yeni ad"
      expect(seller).to be_valid
    end
  end

  describe Product do
    it "accepts a seller-role owner" do
      expect(Product.new(product_attributes(seller: persisted_user(role: "seller")))).to be_valid
    end

    it "rejects buyers and admins as product owners" do
      %w[buyer admin].each do |role|
        product = Product.new(product_attributes(seller: persisted_user(role: role)))
        expect(product).not_to be_valid, role
        expect(product.errors[:seller]).to include("satıcı rolüne sahip olmalıdır")
      end
    end

    it "only checks the owner role when the owner changes" do
      former_seller = persisted_user(id: 7, role: "buyer")
      product = preload_association(persisted_product(seller_id: former_seller.id), :seller, former_seller)

      product.stock = 9
      expect(product).to be_valid

      product.seller = persisted_user(id: 8, role: "buyer")
      expect(product).not_to be_valid
      expect(product.errors[:seller]).to be_present
    end

    it "creates metrics lazily for products without metadata" do
      metadata = ProductMetadata.new
      product = preload_association(persisted_product, :product_metadata, nil)
      expect(product).to receive(:create_product_metadata!).once.and_return(metadata)

      expect(product.metrics).to be(metadata)
    end

    it "reuses existing metrics" do
      metadata = ProductMetadata.new
      product = preload_association(persisted_product, :product_metadata, metadata)
      expect(product).not_to receive(:create_product_metadata!)

      expect(product.metrics).to be(metadata)
    end
  end
end
