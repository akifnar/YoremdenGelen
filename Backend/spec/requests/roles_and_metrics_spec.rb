require "rails_helper"

# Kullanıcılar, ürünler ve metrik kayıtları bellekte kurulur (InMemoryRecords); oturum DB'ye yazılmadan açılır.
# Controller'ın davranışı (yetki, parametre doğrulama, hangi model metodunu çağırdığı) test edilir; sayaçların
# kendisi model seviyesinde ayrıca test edilir.
RSpec.describe "Roller, satıcı paneli ve ürün metrikleri", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:buyer) { persisted_user(id: 11, role: "buyer") }
  let(:seller) { persisted_user(id: 12, role: "seller") }
  let(:admin) { persisted_user(id: 13, role: "admin") }
  let(:product) { persisted_product(id: 21, seller_id: seller.id) }

  describe "rol bazlı erişim (controller seviyesi)" do
    it "keeps buyers out of the seller area and hides product sharing from them" do
      sign_in_stubbed(buyer)
      expect(buyer).not_to receive(:products)

      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Ürünlerini paylaş", "Panelim")

      get seller_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Bu alan yalnızca satıcılara açıktır")

      post seller_products_path, params: { product: { name: "X" } }, headers: turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "keeps sellers and admins out of the cart" do
      [ seller, admin ].each do |user|
        sign_in_stubbed(user)

        get about_path
        expect(response.body).not_to include(%(id="cart_badge"))

        post cart_items_path, params: { product_id: 1, quantity: 1 }, headers: turbo_stream
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("Sepet yalnızca alıcı hesaplarına açıktır")
      end
    end

    it "does not give admins the seller area" do
      sign_in_stubbed(admin)
      get seller_root_path
      expect(response).to redirect_to(root_path)
    end

    it "sends sellers from the home page to their dashboard and shows the sharing link" do
      sign_in_stubbed(seller)

      get root_path
      expect(response).to redirect_to(seller_root_path)

      get products_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ürünlerini paylaş", "Panelim")
      expect(response.body).not_to include(">Katalog<")
    end

    it "never forwards a requested role to the registration job" do
      expect do
        post register_path, params: { user: { name: "Yeni", email: "yeni@example.com", password: "secret123", role: "seller" } }
      end.to have_enqueued_job(UserRegistrationJob).with(hash_excluding(:role))
      expect(response).to redirect_to(login_path)
    end
  end

  describe "admin rol ataması" do
    before do
      sign_in_stubbed(admin)
      allow(User).to receive(:find).and_call_original
      [ buyer, seller, admin ].each { |user| allow(User).to receive(:find).with(user.id.to_s).and_return(user) }
    end

    it "promotes a buyer to seller with a turbo stream row update" do
      allow(buyer).to receive(:update) { |attributes| buyer.assign_attributes(attributes) || true }

      patch admin_user_path(buyer), params: { user: { role: "seller" } }, headers: turbo_stream

      expect(response).to have_http_status(:ok)
      expect(buyer).to have_received(:update).with(role: "seller")
      expect(response.body).to include(%(target="user_#{buyer.id}"), "Satıcı")
    end

    it "validates the role parameter in the controller before touching the model" do
      expect(buyer).not_to receive(:update)
      expect(admin).not_to receive(:update)

      { [ buyer, "" ] => "Rol seçilmelidir", [ buyer, "superuser" ] => "Geçersiz rol: superuser",
        [ admin, "buyer" ] => "Kendi rolünüzü değiştiremezsiniz" }.each do |(user, role), message|
        patch admin_user_path(user), params: { user: { role: role } }, headers: turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(message)
      end
    end

    it "surfaces model validation errors without saving (seller with active products)" do
      allow(seller).to receive(:products).and_return(double("products", active: double("active", exists?: true)))
      expect(seller).not_to receive(:save!)

      patch admin_user_path(seller), params: { user: { role: "buyer" } }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("yayında ürünü olan satıcı", %(target="user_#{seller.id}"))
      expect(seller.role).to eq("seller")
    end

    it "returns 404 for unknown users" do
      patch admin_user_path(id: 0), params: { user: { role: "seller" } }, headers: turbo_stream
      expect(response).to have_http_status(:not_found)
    end

    it "is not available to non-admins" do
      sign_in_stubbed(seller)
      expect(buyer).not_to receive(:update)

      patch admin_user_path(buyer), params: { user: { role: "admin" } }, headers: turbo_stream
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "satıcı ürün parametreleri (controller seviyesi doğrulama)" do
    let(:valid) { { name: "Bergama Tulumu", description: "Tulum peyniri", category: "Peynir", price: "300.50", stock: "5" } }

    before { sign_in_stubbed(seller) }

    it "rejects malformed category, price and stock before the model runs" do
      post seller_products_path, params: { product: valid.merge(category: "Kebap", price: "abc", stock: "-2") }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Ana ürün fotoğrafı zorunludur",
        "Kategori listedeki seçeneklerden biri olmalıdır",
        "Fiyat en fazla iki ondalık basamaklı pozitif bir sayı olmalıdır",
        "Stok adedi negatif olmayan bir tam sayı olmalıdır"
      )
      # Yalnızca controller mesajları döner; model doğrulaması hiç çalışmaz.
      expect(response.body).not_to include("Category is not included")
    end

    it "rejects decimal stock and three-decimal prices" do
      post seller_products_path, params: { product: valid.merge(price: "10.999", stock: "1.5") }, headers: turbo_stream
      expect(response.body).to include(
        "Fiyat en fazla iki ondalık basamaklı pozitif bir sayı olmalıdır",
        "Stok adedi negatif olmayan bir tam sayı olmalıdır"
      )
    end

    context "when updating" do
      before { allow(seller).to receive(:products).and_return(double("products", find: product, new: Product.new)) }

      it "validates only the submitted fields and does not save invalid input" do
        expect(product).not_to receive(:save)

        patch seller_product_path(product), params: { product: { stock: "x" } }, headers: turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Stok adedi negatif olmayan bir tam sayı olmalıdır")
        expect(response.body).not_to include("Fiyat en fazla")
      end

      it "still runs model validations for well-formed but invalid values" do
        patch seller_product_path(product), params: { product: { price: "0" } }, headers: turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Price Fiyat 0&#39;dan büyük olmalıdır")
      end

      it "saves valid input" do
        expect(product).to receive(:save).and_return(true)

        patch seller_product_path(product), params: { product: { stock: "12" } }, headers: turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(target="product_#{product.id}"), "Stok: 12")
      end
    end
  end

  describe "satıcı paneli grafiği" do
    def product_with_metrics(id, name, metadata)
      preload_association(persisted_product(id: id, name: name, seller_id: seller.id), :product_metadata, metadata)
    end

    let(:products) { relation_double(rows) }

    before do
      sign_in_stubbed(seller)
      allow(seller).to receive(:products).and_return(products)
    end

    context "without active products" do
      let(:rows) { [] }

      it "shows an empty state" do
        get seller_root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Henüz yayında ürünün yok")
      end
    end

    context "with active products" do
      let(:rows) do
        [
          product_with_metrics(31, "Ezine Peyniri", ProductMetadata.new(comment_count: 7)),
          product_with_metrics(32, "Tulum Peyniri", ProductMetadata.new(comment_count: 0)),
          product_with_metrics(33, "Metriksiz Ürün", nil)
        ]
      end

      # Ağırlıklı ortalamanın SQL'i product_rating_spec'te test edilir; burada panelin değerleri doğru yere koyması.
      before do
        allow(Product).to receive(:rating_stats_for).with([ 31, 32, 33 ])
          .and_return(31 => { average: 4.5, count: 2 }, 32 => { average: 3.0, count: 1 })
        allow(Product).to receive(:overall_rating_for).with([ 31, 32, 33 ]).and_return(average: 4.0, count: 3)
      end

      it "totals and charts weighted ratings and comments of the seller's active products" do
        get seller_root_path

        expect(products).to have_received(:active)
        kpis = response.body.scan(%r{<p [^>]*data-kpi>([^<]+)</p>}).flatten
        expect(kpis).to eq([ "4,0 / 5", "7" ]) # ağırlıklı ortalama puan, toplam yorum
        expect(response.body).to include("3 değerlendirme", "Ezine Peyniri", "Tulum Peyniri", "Metriksiz Ürün", "width: 90.0%", "width: 100.0%")
        expect(response.body).to include("Ürün bazında ilgi grafiği", "Tablo görünümü")
      end
    end
  end
end
