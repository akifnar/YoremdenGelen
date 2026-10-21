require "rails_helper"

RSpec.describe ProductPurchase, type: :model do
  let(:buyer) { persisted_user(id: 81, role: "buyer") }
  let(:product) { persisted_product(id: 82) }

  describe "doğrulamalar (bellekte)" do
    it "only accepts ratings between 1 and 5" do
      purchase = ProductPurchase.new(user: buyer, product: product, rating: 6)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:rating]).to include("1 ile 5 arasında olmalıdır")

      purchase.rating = nil
      expect(purchase).to be_valid
    end

    it "belongs to buyers only" do
      purchase = ProductPurchase.new(user: persisted_user(id: 83, role: "seller"), product: product)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:user]).to include("alıcı olmalıdır")
    end
  end

  describe "User#purchase_of" do
    it "does not query for non-buyers" do
      seller = persisted_user(id: 84, role: "seller")
      expect(seller).not_to receive(:product_purchases)
      expect(seller.purchase_of(product)).to be_nil
    end

    it "looks the purchase up through the (user_id, product_id) unique index" do
      index = ActiveRecord::Base.connection.indexes(:product_purchases).find { |i| i.columns == %w[user_id product_id] }
      expect(index&.unique).to be(true)
    end
  end

  # DB zorunlu: benzersiz index, satır kilidi ve atomik sayaç güncellemesi test ediliyor.
  describe "kalıcı davranış" do
    let(:buyer) { User.create!(name: "Alıcı", email: "buyer@example.com", password: "secret123") }
    let(:product) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 3) }

    it "records a purchase once per buyer and product" do
      first = ProductPurchase.record!(user: buyer, product: product)
      expect(ProductPurchase.record!(user: buyer, product: product)).to eq(first)
      expect(buyer.purchase_of(product)).to eq(first)
      expect(ProductPurchase.count).to eq(1)
    end

    it "rates once, updates the product average in the same step and rejects a second rating" do
      purchase = ProductPurchase.record!(user: buyer, product: product)

      purchase.rate!(4)
      expect(purchase.reload).to be_rated
      expect(product.metrics.reload).to have_attributes(rating_sum: 4, rating_count: 1)

      expect { purchase.rate!(5) }.to raise_error(ActiveRecord::RecordInvalid, /değiştirilemez/)
      expect(purchase.reload.rating).to eq(4)
      expect(product.metrics.reload).to have_attributes(rating_sum: 4, rating_count: 1)
    end

    it "keeps ratings in range at the database level too" do
      purchase = ProductPurchase.record!(user: buyer, product: product)
      expect { purchase.update_column(:rating, 9) }.to raise_error(ActiveRecord::StatementInvalid, /product_purchases_rating_range/)
    end
  end
end
