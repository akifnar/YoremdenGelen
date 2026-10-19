require "rails_helper"

# Ürün metrikleri: tıklanma, üzerine gelme, ortalama puan ve toplam yorum ayrı ayrı test edilir.
# Sayaçlar eşzamanlı isteklerde kaybolmasın diye atomik SQL UPDATE ile artar; bu yüzden artış testleri DB'ye yazar.
RSpec.describe ProductMetadata, type: :model do
  let(:metadata) { Product.create!(name: "Ezine Peyniri", description: "x", category: "Peynir", price: 100, stock: 3).metrics }

  def counters
    metadata.reload.slice(:click_count, :hover_count, :rating_sum, :rating_count, :comment_count).symbolize_keys
  end

  describe "tıklanma" do
    it "increments only the click count" do
      expect { 2.times { metadata.record_click! } }.to change { counters }
        .from(hash_including(click_count: 0, hover_count: 0, comment_count: 0))
        .to(hash_including(click_count: 2, hover_count: 0, comment_count: 0))
    end
  end

  describe "üzerine gelme" do
    it "increments only the hover count" do
      expect { metadata.record_hover! }.to change { counters }
        .from(hash_including(hover_count: 0, click_count: 0))
        .to(hash_including(hover_count: 1, click_count: 0))
    end
  end

  describe "ortalama puan" do
    it "is 0 without ratings and averages the recorded stars to one decimal" do
      expect(metadata.average_rating).to eq(0.0)

      [ 5, 4, 4 ].each { |stars| metadata.record_rating!(stars) }

      expect(counters).to include(rating_sum: 13, rating_count: 3, click_count: 0, comment_count: 0)
      expect(metadata.average_rating).to eq(4.3)
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
    metadata = ProductMetadata.new(product: persisted_product, hover_count: -1)
    expect(metadata).not_to be_valid
    expect(metadata.errors[:hover_count]).to be_present
  end
end
