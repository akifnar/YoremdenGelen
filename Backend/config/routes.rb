Rails.application.routes.draw do
  root "products#index"

  # Oturum, kayıt ve e-posta doğrulama
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  post "auth/google", to: "sessions#google", as: :google_auth
  get "register", to: "registrations#new", as: :register
  post "register", to: "registrations#create"
  get "verify-email", to: "email_verifications#show", as: :verify_email
  post "verify-email", to: "email_verifications#create"

  # Katalog kartı yalnızca ana görseli gösterir; galeri fotoğrafları sadece ürün sayfasında (show) açılır.
  resources :products, only: [ :index, :show ], path: "urunler" do
    # Ürün yorumları: sayfalama (Turbo Frame) ve alıcı yorumu yazma.
    resources :comments, only: [ :index, :create ], path: "yorumlar"
  end

  # Alıcı kendi yorumunu siler; satıcı alıcı yorumuna tek cevap yazar; alıcılar like/dislike verir.
  resources :comments, only: :destroy, path: "yorumlar" do
    resource :reply, only: :create, path: "cevap", controller: "comment_replies"
    resource :reaction, only: :create, path: "tepki", controller: "comment_reactions"
  end

  # Kategori bazında sayfalama (Pagy); anasayfadaki her kategori bölümü bu adrese bağlanır.
  resources :categories, only: :show, param: :slug, path: "kategoriler"

  # Satıcının herkese açık sayfası: profil ve yayındaki tüm ürünleri.
  resources :sellers, only: :show, path: "saticilar"

  resource :cart, only: [ :show ], path: "sepet" do
    resources :items, controller: "cart_items", only: [ :create, :update, :destroy ]
    # Sepeti siparişe çevirir (gerçek ödeme yok); sipariş ürünlere yorum yetkisi verir.
    resource :checkout, only: :create, path: "siparis"
  end

  # Satıcının anasayfası: ürün metrikleri paneli. Ürün paylaşma yalnızca satıcı rolüne açıktır.
  namespace :seller, path: "satici" do
    root "dashboard#show"
    resources :products, path: "urunler", only: [ :index, :new, :create, :edit, :update, :destroy ]
  end

  namespace :admin do
    resources :users, only: [ :index, :create, :update, :destroy ]
  end

  # Alıcı ve satıcının profil ayarları (alıcı: ad; satıcı: ad ve profil resmi); kaydetmek için mevcut şifre istenir.
  resource :settings, only: [ :show, :update ], path: "ayarlar"

  get "hakkimizda", to: "pages#about", as: :about
  get "sss", to: "pages#faq", as: :faq
  get "teslimat-iade", to: "pages#shipping_returns", as: :shipping_returns
  get "gizlilik", to: "pages#privacy", as: :privacy
  get "kullanim-kosullari", to: "pages#terms", as: :terms

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Bilinmeyen HTML sayfaları için 404 (Active Storage ve Action Cable yolları hariç).
  get "*path", to: "pages#not_found",
               constraints: ->(request) { !request.path.start_with?("/rails/", "/cable") }
end
