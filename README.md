# Yöremden Gelen

Yöresel ürünleri keşfetmek, sepetten sipariş vermek ve satıcı hesabıyla ürün yayınlamak için hazırlanmış bir mağaza uygulaması.

## Teknolojiler

- **Uygulama:** Ruby 3.4, Rails 8.1, Hotwire (Turbo + Stimulus), Importmap, Propshaft
- **Arayüz:** Tailwind CSS (`tailwindcss-rails`), Pagy ile sayfalama
- **Veri:** PostgreSQL, Active Storage (ürün ve profil görselleri), Solid Queue / Cache / Cable
- **Kimlik doğrulama:** `has_secure_password` (bcrypt), şifreli cookie'ler, isteğe bağlı Google girişi (OAuth authorization code akışı)
- **Test ve kalite:** RSpec, RuboCop (rails-omakase), Brakeman, bundler-audit
- **Geliştirme ortamı:** Docker Compose

Uygulama tek bir Rails monolitidir; sayfalar sunucuda render edilir, etkileşimler Turbo Frame/Stream ve Stimulus controller'larıyla sağlanır. Ayrı bir frontend projesi yoktur.

## Başlangıç

Gerekli araçlar: Docker ve Docker Compose. Depo kök dizininde:

```sh
docker compose up --build
```

Compose üç servis başlatır:

| Servis | Görevi |
| --- | --- |
| `db` | PostgreSQL 18 |
| `web` | Gem'leri kurar, `bin/rails db:prepare` çalıştırır ve Rails sunucusunu 3000 portunda açar |
| `css` | Tailwind çıktısını (`app/assets/builds/tailwind.css`) değişikliklerde yeniden üretir |

İlk açılışta `db:prepare` migration'ları ve seed'leri otomatik çalıştırır; ayrıca bir kurulum komutu gerekmez.

- Uygulama: <http://localhost:3000>
- Sağlık kontrolü: <http://localhost:3000/up>

### Docker olmadan

Yerelde Ruby 3.4 ve PostgreSQL kuruluysa `DB_HOST`, `DB_USERNAME` ve `DB_PASSWORD` değişkenlerini ayarlayıp:

```sh
cd Backend
bin/setup   # bundle install + db:prepare, ardından bin/dev ile sunucu ve Tailwind watcher
```

## Ortam değişkenleri

Hepsi isteğe bağlıdır; boş bırakıldığında ilgili özellik devre dışı kalır veya geliştirme varsayılanı kullanılır. Değerleri kök dizindeki bir `.env` dosyasına ya da kabuk ortamına yazabilirsiniz.

| Değişken | Açıklama |
| --- | --- |
| `APP_HOST`, `APP_PORT` | E-posta bağlantılarında kullanılan adres (varsayılan `localhost:3000`) |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Google ile giriş; biri eksikse Google butonu gösterilmez. Google Cloud Console'da yetkili yönlendirme adresi olarak `http://localhost:3000/auth/google` eklenmelidir |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_AUTHENTICATION` | Doğrulama e-postalarının gönderimi |
| `INITIAL_USER_EMAIL`, `INITIAL_USER_PASSWORD`, `INITIAL_ADMIN_EMAIL`, `INITIAL_ADMIN_PASSWORD` | Seed ile oluşturulan ilk hesaplar |

## Özellikler

- **Katalog:** Kategori bölümleriyle anasayfa, her kategori için ayrı sayfalı liste, ürün fotoğraf galerisi ve satıcıların herkese açık sayfaları
- **Roller:** Alıcı, satıcı ve admin; yayında ürünü olan satıcının rolü değiştirilemez
- **Sepet ve sipariş:** Kullanıcıya bağlı sepet, güncel fiyat/stok kontrolü, geri alınabilir sepet bildirimleri ve sepeti siparişe çeviren ödeme adımı (gerçek ödeme alınmaz)
- **Yorum ve puanlama:** Ürünü satın alan alıcı yıldız ve yorum bırakır; satıcı her yoruma bir kez cevap verir; ürünü satın alan alıcılar yorumlara beğeni/beğenmeme tepkisi verir. Ürün puanı ağırlıklı ortalamayla hesaplanır
- **Satıcı paneli:** Ürün ekleme, düzenleme, yayından kaldırma ve ürün metrikleri
- **Hesap:** Kayıt, e-posta doğrulama, 12 saatlik kayan oturum süresi, 30 günlük "beni hatırla" ve satıcılar için profil ayarları (ad ve profil resmi; alıcılara şimdilik kapalı)
- **Admin:** Kullanıcı oluşturma, rol güncelleme ve silme

Oturum ve hatırlama token'ları cookie'de şifreli tutulur; veritabanında yalnızca SHA-256 özetleri saklanır.

## Geliştirme hesapları

Seed'ler ilk hesapları ve Faker ile bir demo kataloğu oluşturur:

| Hesap | E-posta | Parola |
| --- | --- | --- |
| Alıcı | `user@mail.com` | `user12345` |
| Admin | `admin@mail.com` | `admin12345` |
| Demo satıcılar (10) ve alıcılar (50) | `@yoremdengelen.test` uzantılı adresler | `password123` |

`user@mail.com` her ürünü satın almış sayılır, böylece her ürüne yorum yazabilir. Seed'ler mevcut hesapların parolalarını her çalışmada sıfırlamaz.

> Production ortamında varsayılan hesapları kullanmayın. `INITIAL_*` değişkenleri verilmezse seed production'da hata verir; parolalar en az 8 karakter olmalıdır.

## Test ve kalite kontrolleri

Spec'ler büyük ölçüde bellek içi kayıtlar ve double'larla çalışır, ancak şema kontrolü için test veritabanının hazır olması gerekir:

```sh
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

Stil ve güvenlik kontrolleri (`bin/ci` ile hepsi birlikte çalıştırılabilir):

```sh
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit
```

## Proje yapısı

```text
.
├── docker-compose.yml
└── Backend/                  Rails uygulaması
    ├── app/controllers/      Vitrin, sepet, sipariş, yorum; seller/ ve admin/ namespace'leri
    ├── app/javascript/       Stimulus controller'ları
    ├── app/views/            ERB şablonları ve Turbo partial'ları
    ├── db/seeds.rb           İlk hesaplar ve demo kataloğu
    └── spec/                 Model, request, job, mailer ve view spec'leri
```
