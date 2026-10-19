require "rails_helper"

# Sayfalar bellekteki kayıtlarla render edilir (InMemoryRecords). Gerçek kayıt yalnızca şifreyle girişte
# (oturum token'ının kullanıcıya yazılması) kullanılır.
RSpec.describe "HTML sayfaları ve Turbo yanıtları", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  describe "katalog" do
    let(:product) { persisted_product(id: 109) }

    it "renders the product page and swaps a card photo inside its turbo frame" do
      stub_active_product_lookup(product)
      allow(product).to receive(:metrics).and_return(instance_double(ProductMetadata, record_click!: true))

      get product_path(product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="details_product_#{product.id}"), product.name)

      get photo_product_path(product, index: -1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame class="relative block" id="photo_product_#{product.id}">), "images.unsplash.com")
    end

    # Product#broadcast_catalog_changes bu partial'ları ApplicationController.render ile üretir.
    it "renders the partials used by product broadcasts outside a request" do
      expect(ApplicationController.render(partial: "products/card", locals: { product: product })).to include(%(id="card_product_#{product.id}"))
      expect(ApplicationController.render(partial: "products/details", locals: { product: product })).to include(%(id="details_product_#{product.id}"))
    end

    it "shows a 404 page for unknown products and paths" do
      stub_active_product_lookup

      get product_path("olmayan-urun")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Bu ürün artık mevcut değil.")

      get "/boyle-bir-sayfa-yok"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Aradığın sayfa burada yok.")
    end

    it "renders the static pages" do
      [ about_path, faq_path, shipping_returns_path, privacy_path, terms_path ].each do |path|
        get path
        expect(response).to have_http_status(:ok), path
      end
    end
  end

  describe "oturum" do
    # DB zorunlu: şifre doğrulaması ve oturum token'ının kullanıcıya yazılması test ediliyor.
    it "logs in through the HTML form and shows the account header" do
      user = User.create!(name: "Ayşe", email: "ayse@example.com", password: "secret123", email_verified_at: Time.current)

      get login_path
      expect(response.body).to include("Giriş yap")

      post login_path(returnTo: "/sepet"), params: { user: { email: user.email, password: "wrong-pass" } }
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("E-posta veya şifre hatalı")

      post login_path(returnTo: "/sepet"), params: { user: { email: user.email, password: "secret123" } }
      expect(response).to redirect_to("/sepet")
      follow_redirect!
      expect(response.body).to include("Çıkış yap", %(id="cart_badge"), "Sepetiniz henüz boş.")
      expect(response.body).not_to include(%(aria-label="Ayarlar")) # alıcıların ayarlar menüsü şimdilik kapalı
    end

    it "re-renders registration errors" do
      get register_path
      expect(response).to have_http_status(:ok)

      post register_path, params: { user: { name: "", email: "hatali", password: "123" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it "verifies an email with a turbo stream response" do
      unverified = persisted_user(id: 42, email_verified_at: nil, email_verification_token: "dogrulama-token")
      allow(User).to receive(:find_by).and_call_original
      allow(User).to receive(:find_by).with(email_verification_token: "dogrulama-token").and_return(unverified)
      expect(unverified).to receive(:verify_email!).with("dogrulama-token").and_return(true)

      get verify_email_path(token: "dogrulama-token")
      expect(response.body).to include("E-posta doğrulanıyor…", %(data-controller="auto-submit"))

      post verify_email_path, params: { token: "dogrulama-token" }, headers: turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(target="verification_result"), "E-posta adresi doğrulandı")
    end
  end

  describe "sayfa geçişleri" do
    it "sends only the page content for Turbo-Frame: main requests" do
      get about_path, headers: { "Turbo-Frame" => "main" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame id="main">), "Güzel şeyler", "<title>Hakkımızda · Yöremden Gelen</title>")
      expect(response.body).not_to include("Hesap ve sepet işlemleri", "Alt menü", %(id="notifications"))

      get about_path
      expect(response.body).to include(%(data-turbo-action="advance" id="main"), "Hesap ve sepet işlemleri", "Alt menü", %(id="notifications"))
    end
  end
end
