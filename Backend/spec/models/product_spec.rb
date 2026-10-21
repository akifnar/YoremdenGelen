require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "seller association" do
    it "belongs to one seller when the product is seller-owned" do
      seller = User.create!(name: "Seller", email: "seller@example.com", password: "secret123", role: "seller")
      product = described_class.create!(
        name: "Local cheese",
        description: "Made by the seller",
        price: 50,
        stock: 4,
        category: "Peynir",
        seller: seller
      )
      product.main_image.attach(io: StringIO.new("test image"), filename: "test.jpg", content_type: "image/jpeg")
      product.save!

      expect(product.seller).to eq(seller)
    end

    it "allows legacy catalog products without a seller" do
      product = described_class.new(
        name: "Legacy catalog item",
        description: "Imported before seller ownership was added",
        price: 50,
        stock: 4,
        category: "Peynir"
      )

      expect(product).to be_valid
    end
  end

  describe 'validations' do
    let(:product) do
      Product.new(
        name: 'Test Ürünü',
        description: 'Test Açıklaması',
        price: 100.0,
        stock: 50,
        category: "Peynir",
        is_active: true
      )
    end

    context 'name' do
      it 'is invalid without a name' do
        product.name = nil
        product.valid?
        expect(product.errors[:name]).to include("Ürün adı boş bırakılamaz")
      end
    end

    context 'description' do
      it 'rejects descriptions over the database limit' do
        product.description = "a" * (Product::DESCRIPTION_MAX_LENGTH + 1)
        expect(product).not_to be_valid
        expect(product.errors[:description]).to be_present
      end

      it 'is invalid without a description' do
        product.description = nil
        product.valid?
        expect(product.errors[:description]).to include("Ürün açıklaması boş bırakılamaz")
      end
    end


    context 'price' do
      it 'is invalid without a price' do
        product.price = nil
        product.valid?
        expect(product.errors[:price]).to include("Fiyat alanı zorunludur")
      end

      it 'is invalid if price is zero' do
        product.price = 0
        product.valid?
        expect(product.errors[:price]).to include("Fiyat 0'dan büyük olmalıdır")
      end
    end

    context 'stock' do
      it 'is invalid without a stock' do
        product.stock = nil
        product.valid?
        expect(product.errors[:stock]).to include("Stok alanı zorunludur")
      end

      it 'is invalid if stock is negative' do
        product.stock = -1
        product.valid?
        expect(product.errors[:stock]).to include("Stok adedi negatif olamaz")
      end
    end


    context 'category' do
      it 'rejects categories outside the seller category list' do
        product.category = "Bilinmeyen kategori"
        expect(product).not_to be_valid
        expect(product.errors[:category]).to be_present
      end
    end
  end
end
