require "rails_helper"

# DB zorunlu: test edilen şey SQL'in kendisi (popülerlik ORDER BY'ı, Pagy'nin OFFSET/LIMIT'i ve GROUP BY sayımı).
RSpec.describe "Kategori bazlı katalog sayfalama (Pagy)", type: :request do
  # Skorlar: tıklanma×1 + yorum×5 + yıldız toplamı×2 + hover÷10
  # Beklenen sıra: hover(200) > yorum(150) > yıldız(120) > tıklanma(100) > az tıklanma(50) > sıfır-1 > sıfır-2
  let!(:peynirler) do
    {
      "Tıklanan Peynir" => { click_count: 100 },
      "Yorumlanan Peynir" => { comment_count: 30 },
      "Puanlanan Peynir" => { rating_sum: 60, rating_count: 12 },
      "Bakılan Peynir" => { hover_count: 2_000 },
      "Az Tıklanan Peynir" => { click_count: 50 },
      "Sıfır Peynir 1" => {},
      "Sıfır Peynir 2" => {}
    }.map do |name, metrics|
      Product.create!(name: name, description: "x", category: "Peynir", price: 100, stock: 3).tap { |product| product.metrics.update!(metrics) }
    end
  end

  before do
    Product.create!(name: "Gemlik Zeytini", description: "x", category: "Zeytin", price: 100, stock: 3)
    Product.create!(name: "Tükenen Bal", description: "x", category: "Diğer Yöresel Ürünler", price: 100, stock: 0)
  end

  def card_names(html)
    html.scan(%r{<h3 class="[^"]*">\s*<a [^>]*>([^<]+)</a>}).flatten
  end

  it "shows the first 6 products of each non-empty category by combined popularity, with a link to the next page" do
    get root_path

    frames = response.body.scan(/<turbo-frame [^>]*id="(category_[a-z-]+)"/).flatten
    expect(frames).to eq(%w[category_peynir category_zeytin])
    expect(card_names(response.body).first(6)).to eq(
      [ "Bakılan Peynir", "Yorumlanan Peynir", "Puanlanan Peynir", "Tıklanan Peynir", "Az Tıklanan Peynir", "Sıfır Peynir 1" ]
    )
    expect(response.body).not_to include("Sıfır Peynir 2", "Tükenen Bal")
    expect(response.body).to include(%(href="/kategoriler/peynir?page=2"), "7 ürün · Sayfa 1/2")
  end

  it "renders the requested page of a single category inside its frame" do
    get category_path("peynir", page: 2), headers: { "Turbo-Frame" => "category_peynir" }

    expect(response).to have_http_status(:ok)
    expect(card_names(response.body)).to eq([ "Sıfır Peynir 2" ])
    expect(response.body).to include(%(<turbo-frame class="block scroll-mt-24" id="category_peynir">), %(href="/kategoriler/peynir?page=1"))
  end

  it "validates the page parameter: invalid values fall back to page 1, overflow to the last page" do
    frame = { "Turbo-Frame" => "category_peynir" }
    get category_path("peynir", page: "abc"), headers: frame
    expect(response.body).to include("Sayfa 1/2")

    get category_path("peynir", page: 999), headers: frame
    expect(response.body).to include("Sayfa 2/2")
  end

  it "shows only that category's products, 12 per page, on the category page" do
    get category_path("peynir"), headers: { "Turbo-Frame" => "main" }

    expect(card_names(response.body).size).to eq(7)
    expect(response.body).not_to include("Gemlik Zeytini", %(id="category_peynir"))
    expect(response.body).to include("<h1", "Peynir", "7 ürün")
  end

  it "lists every category in the header menu without counting products" do
    count_queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count_queries << payload[:sql] if payload[:sql].match?(/COUNT/i)
    end
    get about_path
    ActiveSupport::Notifications.unsubscribe(subscriber)

    menu = response.body[/<nav aria-label="Kategoriler".*?<\/nav>/m]
    expect(menu.scan(%r{href="/kategoriler/([a-z-]+)"}).flatten).to eq(Product::CATEGORIES.map(&:parameterize))
    expect(count_queries).to be_empty
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "returns 404 for unknown categories" do
    get category_path("olmayan-kategori")
    expect(response).to have_http_status(:not_found)
  end
end
