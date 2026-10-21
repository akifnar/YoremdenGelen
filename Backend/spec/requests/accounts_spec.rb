require "rails_helper"

# Admin kullanıcı ekleme, profil ayarları, ürün sayfasında satıcı ve çıkış. Kayıtlar bellekte; save gerektiren
# başarılı yollar mock'lanır, model doğrulamaları ise gerçek (yazma yapmayan) valid? çağrısıyla çalışır.
RSpec.describe "Hesaplar ve profil", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:password_digest) { BCrypt::Password.create("secret123", cost: BCrypt::Engine::MIN_COST) }
  let(:buyer) { persisted_user(id: 51, role: "buyer", password_digest: password_digest) }
  let(:seller) { persisted_user(id: 52, role: "seller", name: "Ayşe Üretici", password_digest: password_digest) }
  let(:admin) { persisted_user(id: 53, role: "admin") }

  describe "admin kullanıcı ekleme" do
    let(:valid) { { name: "Yeni Satıcı", email: "yeni@example.com", password: "secret123", role: "seller" } }

    before { sign_in_stubbed(admin) }

    it "creates a verified user with the chosen role" do
      created = nil
      allow(User).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap do |user|
          created ||= user # Başarıdan sonra formu sıfırlamak için kurulan boş User.new yakalanmaz.
          allow(user).to receive(:save) { user.id = 99 }
        end
      end

      post admin_users_path, params: { user: valid }, headers: turbo_stream

      expect(response).to have_http_status(:created)
      expect(created).to have_attributes(name: "Yeni Satıcı", email: "yeni@example.com", role: "seller")
      expect(created.email_verified_at).to be_present
      expect(created.authenticate("secret123")).to eq(created)
      expect(response.body).to include(%(target="admin_users"), %(target="admin_new_user_form"), "Yeni Satıcı eklendi.")
    end

    it "rejects missing fields and unknown roles in the controller without saving" do
      expect_any_instance_of(User).not_to receive(:save)

      post admin_users_path, params: { user: { name: "", email: "", password: "", role: "owner" } }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Zorunlu alanlar boş bırakılamaz: Ad, E-posta, Şifre", "Geçersiz rol: owner")
    end

    it "surfaces model validation errors" do
      post admin_users_path, params: { user: valid.merge(email: "gecersiz", password: "123") }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(target="admin_new_user_form"), "Email is invalid", "Password is too short")
    end

    it "is only available to admins" do
      sign_in_stubbed(seller)
      post admin_users_path, params: { user: valid }, headers: turbo_stream
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "ayarlar" do
    it "is available only to sellers for now, not buyers, admins or guests" do
      get settings_path
      expect(response).to redirect_to(login_path(returnTo: "/ayarlar"))

      [ buyer, admin ].each do |user|
        sign_in_stubbed(user)
        get settings_path
        expect(response).to redirect_to(root_path)
      end

      sign_in_stubbed(seller)
      get settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Profilin", "Ad soyad", "Mevcut şifre", "Profil resmi")
    end

    it "puts settings (sellers only) and logout in the profile menu" do
      sign_in_stubbed(seller)
      get about_path
      profile_menu = response.body[/<div id="profile_menu".*?<\/div>/m]
      expect(profile_menu).to include(%(aria-label="Ayarlar"), "Çıkış yap")

      [ buyer, admin ].each do |user|
        sign_in_stubbed(user)
        get about_path
        expect(response.body).not_to include(%(aria-label="Ayarlar"))
        expect(response.body).to include("Çıkış yap")
      end
    end

    it "does not let buyers update their profile for now" do
      sign_in_stubbed(buyer)
      expect(buyer).not_to receive(:save)

      patch settings_path, params: { user: { name: "Yeni Ad", current_password: "secret123" } }
      expect(response).to redirect_to(root_path)
    end

    context "when updating" do
      before { sign_in_stubbed(seller) }

      it "requires the current password" do
        expect(seller).not_to receive(:save)

        patch settings_path, params: { user: { name: "Yeni Ad" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Değişiklikleri kaydetmek için mevcut şifreni gir")
      end

      it "rejects a wrong current password (bcrypt comparison)" do
        expect(seller).not_to receive(:save)

        patch settings_path, params: { user: { name: "Yeni Ad", current_password: "yanlis-sifre" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Mevcut şifre hatalı")
        expect(seller.name).not_to eq("Yeni Ad")
      end

      it "runs model validations after the password check" do
        patch settings_path, params: { user: { name: "a" * 121, current_password: "secret123" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name is too long")
      end
    end

    context "when a seller updates the profile picture" do
      before { sign_in_stubbed(seller) }

      it "saves an image avatar" do
        expect(seller).to receive(:save).and_return(true)
        avatar = Rack::Test::UploadedFile.new(StringIO.new("png"), "image/png", original_filename: "ben.png")

        patch settings_path, params: { user: { avatar: avatar, current_password: "secret123" } }

        expect(response).to redirect_to(settings_path)
        expect(seller.attachment_changes["avatar"]).to be_present
      end

      it "rejects non-image avatars in the controller" do
        expect(seller).not_to receive(:save)
        upload = Rack::Test::UploadedFile.new(StringIO.new("%PDF"), "application/pdf", original_filename: "cv.pdf")

        patch settings_path, params: { user: { avatar: upload, current_password: "secret123" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Avatar PNG, JPEG veya WebP olmalıdır")
      end
    end
  end

  describe "ürün sayfasında satıcı" do
    it "shows the seller's name linking to the seller page" do
      product = preload_association(persisted_product(id: 61, seller_id: seller.id), :seller, seller)
      stub_active_product_lookup(product)

      get product_path(product)

      expect(response.body).to include("Satıcı", "Ayşe Üretici")
      expect(response.body).to include(%(href="/saticilar/#{seller.id}")) # satıcının diğer ürünlerine bağlantı
    end

    it "falls back to the store name for products without a seller" do
      product = preload_association(persisted_product(id: 62), :seller, nil)
      stub_active_product_lookup(product)

      get product_path(product)

      expect(response.body).to include("Satıcı: Yöremden Gelen")
    end
  end

  describe "çıkış" do
    it "revokes the session and deletes the auth cookies" do
      sign_in_stubbed(buyer)
      # Rails yalnızca istekte bulunan cookie'ler için silme başlığı gönderir.
      set_encrypted_cookie(:remember_token, "remember")
      allow(buyer).to receive(:remember_token_matches?).and_return(true)
      expect(buyer).to receive(:revoke_tokens!)

      delete logout_path

      expect(response).to redirect_to(root_path)
      set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
      %w[session_token remember_token].each { |name| expect(set_cookie).to match(/^#{name}=;/) }
    end
  end
end
