# Yöremden Gelen

Yöresel ürünleri keşfetmek, sepetten satın almak ve üretici hesabıyla ürün listelemek için hazırlanmış bir mağaza uygulaması.

## Teknolojiler

- **Backend:** Ruby on Rails JSON API, PostgreSQL, Active Storage, Active Job
- **Frontend:** React, TypeScript, Vite, React Router, Tailwind CSS
- **Geliştirme ortamı:** Docker Compose

## Başlangıç

Gerekli araçlar: Docker ve Docker Compose. Depo kök dizininde:

```sh
docker compose up --build -d
```

Compose, PostgreSQL, Rails çalışma konteyneri ve Vite frontend’i sağlar. Backend konteyneri geliştirme için açık bekler; ilk kurulumda veritabanını hazırlayın:

```sh
docker compose exec backend bundle install
docker compose exec backend bin/rails db:prepare
```

Rails API sunucusunu ayrıca çalıştırın:

```sh
docker compose exec -d backend bin/rails server -b 0.0.0.0
```

Uygulama adresleri:

- Frontend: <http://localhost:5173>
- Backend sağlık kontrolü: <http://localhost:3000/up>

> Frontend container’ı çalıştığında `npm install` işlemini kendi komutunda yürütür. Ortam değişkenleri ve e-posta/Google ayarları için `docker-compose.yml` dosyasını inceleyin.

## Önemli özellikler

- Ürün kataloğu; ürün fotoğraf galerisi, kategoriler ve sayfalama
- Oturum açan kullanıcılara özel sepet ve güncel fiyat/stok bilgisi
- Kayıt, e-posta doğrulama, session cookie ve isteğe bağlı beni hatırla cookie’si
- Kullanıcıların kendi ürünlerini ekleyip düzenleyebildiği satıcı alanı
- Admin kullanıcı yönetimi

## İlk geliştirme hesapları

İlk veritabanı kurulumu seed’leri çalıştırır:

| Rol | E-posta | Parola |
| --- | --- | --- |
| Kullanıcı | `user@mail.com` | `user12345` |
| Admin | `admin@mail.com` | `admin12345` |

Seed’ler mevcut hesap parolalarını her çalışmada sıfırlamaz. Production ortamında bu varsayılanları kullanmayın; `INITIAL_USER_EMAIL`, `INITIAL_USER_PASSWORD`, `INITIAL_ADMIN_EMAIL` ve `INITIAL_ADMIN_PASSWORD` değerlerini güvenli ortam değişkenleri olarak verin.

## Test ve build

Backend testleri:

```sh
cd Backend
bundle exec rspec
```

Frontend statik kontrol ve üretim build’i:

```sh
cd Frontend
npm run lint
npm run build
```

API istek spec’leri veritabanı gerektirdiğinden test veritabanı `db:prepare` ile hazır olmalıdır. Harici SMTP veya Google OAuth olmadan çalışan spec’ler bunları taklit eder.

## Veri ve görseller

`Backend/db/seeds.rb` geliştirme kataloğunu ve ilk hesapları hazırlar. Ana ve galeri görselleri Active Storage’da tutulur; ürün kartları ek galeri görsellerini yalnızca kullanıcı fotoğraf kontrolüne bastığında ister.
