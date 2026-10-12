require 'rails_helper'

RSpec.describe "Api::Products", type: :request do
  describe "GET /api/products" do
    it "returns one paginated page and does not serialize galleries for every card" do
      existing_count = Product.count
      11.times do |index|
        Product.create!(name: "Paginated dish #{index}", description: "Regional dish", category: "Et ve Şarküteri", price: 10, stock: 2)
      end
      expected_count = existing_count + 11

      get "/api/products", params: { page: 1 }
      body = response.parsed_body
      expect(response).to have_http_status(:success)
      expect(body.fetch("metadata")).to include(
        "current_page" => 1,
        "next_page" => 2,
        "total_count" => expected_count,
        "total_pages" => (expected_count / 10.0).ceil
      )
      expect(body.fetch("data").length).to eq(10)
      expect(body.fetch("data").first).not_to have_key("gallery_image_urls")
      expect(body.fetch("data").first).not_to have_key("sku")

      get "/api/products", params: { page: 2 }
      expect(response.parsed_body.dig("metadata", "current_page")).to eq(2)
      expect(response.parsed_body.dig("metadata", "next_page")).to eq(3)
      expect(response.parsed_body.fetch("data").length).to eq(10)
    end

    it "loads main-image attachments with a bounded number of queries for a page" do
      10.times do |index|
        product = Product.create!(name: "Image dish #{index}", description: "Regional dish", category: "Et ve Şarküteri", price: 10, stock: 2)
        product.main_image.attach(
          io: StringIO.new("image data #{index}"),
          filename: "main-#{index}.jpg",
          content_type: "image/jpeg"
        )
      end

      attachment_queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
        sql = payload[:sql]
        attachment_queries << sql if sql.match?(/SELECT/i) && sql.match?(/active_storage_(attachments|blobs)/)
      end
      get "/api/products", params: { page: 1 }
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(response).to have_http_status(:success)
      expect(attachment_queries.length).to be <= 4
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end

    it "returns attached additional photos on the product detail endpoint" do
      product = Product.create!(name: "Gallery dish", description: "Regional dish", category: "Et ve Şarküteri", price: 10, stock: 2)
      2.times do |index|
        product.gallery_images.attach(
          io: StringIO.new("image data #{index}"),
          filename: "gallery-#{index}.jpg",
          content_type: "image/jpeg"
        )
      end

      get "/api/products/#{product.slug}"

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.fetch("gallery_image_urls").length).to eq(2)
      expect(response.parsed_body).not_to have_key("sku")
    end
  end
end
