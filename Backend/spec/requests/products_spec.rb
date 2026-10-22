require "rails_helper"

# DB zorunlu: Active Storage ekleri gerçek kayıtlarla yükleniyor ve sorgu sayısı ölçülüyor.
RSpec.describe "Ürünler", type: :request do
  def attach(attachment, name)
    attachment.attach(io: StringIO.new(name), filename: "#{name}.jpg", content_type: "image/jpeg")
  end

  it "loads catalog card images with a bounded number of queries" do
    10.times do |index|
      attach(Product.create!(name: "Görselli Ürün #{index}", description: "x", category: "Peynir", price: 10, stock: 2).main_image, "main-#{index}")
    end

    attachment_queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      attachment_queries << payload[:sql] if payload[:sql].match?(/SELECT/i) && payload[:sql].match?(/active_storage_(attachments|blobs)/)
    end
    get root_path
    ActiveSupport::Notifications.unsubscribe(subscriber)

    expect(response.body.scan(%r{/rails/active_storage/blobs/}).size).to eq(ProductsController::HOME_PER_CATEGORY)
    expect(attachment_queries.length).to be <= 4
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  # Kategori sayfası sayfa sayfa (12'şer) yüklenir; kartlar yalnızca ana görseli kullandığı için galeri hiç sorgulanmaz.
  it "paginates the category page and loads only main images without N+1 queries" do
    13.times do |index|
      product = Product.create!(name: "Kategori Ürünü #{index}", description: "x", category: "Peynir", price: 10, stock: 2)
      attach(product.main_image, "main-#{index}")
      attach(product.gallery_images, "gallery-#{index}")
    end

    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      queries << payload[:sql] if payload[:sql].match?(/SELECT/i)
    end
    get category_path("peynir")
    ActiveSupport::Notifications.unsubscribe(subscriber)

    expect(response.body.scan(%r{/rails/active_storage/blobs/}).size).to eq(CategoryPagination::PAGE_PER_PAGE)
    expect(response.body).not_to include("gallery-")
    expect(queries.grep(/FROM "products"/).grep(/LIMIT \$?\d*/).join).to match(/LIMIT/)
    expect(queries.grep(/active_storage_(attachments|blobs)/).length).to be <= 4
    expect(queries.grep(/gallery_images/)).to be_empty
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "shows attached gallery photos on the product page" do
    product = Product.create!(name: "Galerili Ürün", description: "x", category: "Peynir", price: 10, stock: 2)
    2.times { |index| attach(product.gallery_images, "gallery-#{index}") }

    get product_path(product)

    expect(response.body.scan(/data-gallery-target="thumb"/).size).to eq(3) # ana görsel (yedek) + 2 galeri
    expect(response.body).to include("gallery-0.jpg", "gallery-1.jpg")
  end
end
