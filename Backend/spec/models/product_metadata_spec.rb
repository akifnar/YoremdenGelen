require "rails_helper"

# Ürün sayaçları: puan ve toplam yorum ayrı ayrı test edilir (ağırlıklı ortalama: spec/models/product_rating_spec.rb).
# Sayaçlar eşzamanlı isteklerde kaybolmasın diye atomik SQL UPDATE ile artar; bu yüzden artış testleri DB'ye yazar.
RSpec.describe ProductMetadata, type: :model do
  let(:metadata) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 3).metrics }

  def counters
    metadata.reload.slice(:rating_sum, :rating_count, :comment_count).symbolize_keys
  end

  describe "puan" do
    it "adds each rating to the rating sum and count without touching the comment count" do
      [ 5, 4, 4 ].each { |stars| metadata.record_rating!(stars) }

      expect(counters).to eq(rating_sum: 13, rating_count: 3, comment_count: 0)
    end

    it "rejects stars outside 1..5 before touching the database" do
      metadata = ProductMetadata.new
      expect(ProductMetadata).not_to receive(:update_counters)
      expect { metadata.record_rating!(6) }.to raise_error(ArgumentError)
      expect { metadata.record_rating!(0) }.to raise_error(ArgumentError)
    end
  end

  describe "toplam yorum" do
    it "increments only the comment count" do
      expect { 3.times { metadata.record_comment! } }.to change { counters }
        .from(hash_including(comment_count: 0, rating_count: 0))
        .to(hash_including(comment_count: 3, rating_count: 0))
    end
  end

  it "rejects negative counters" do
    metadata = ProductMetadata.new(product: persisted_product, comment_count: -1)
    expect(metadata).not_to be_valid
    expect(metadata.errors[:comment_count]).to be_present
  end
end
