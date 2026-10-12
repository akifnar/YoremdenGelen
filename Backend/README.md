# Rails API

Bu dizin Yöremden Gelen’in Rails JSON API’sini içerir. Proje kurulumu, Docker Compose servisleri ve geliştirme hesapları için depo kökündeki [`README.md`](../README.md) dosyasına bakın.

## Yerel komutlar

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

API, PostgreSQL kullanır. `db:prepare` ilk veritabanı kurulumunda migration’ları ve seed’leri çalıştırır; satıcı ürün sahipliği migration’ı da bu adıma dahildir.

## API alanları

- `POST /api/auth/register`, `POST /api/auth/login`, `DELETE /api/auth/logout`
- `GET /api/products`, `GET /api/products/:slug`
- `GET|POST /api/seller/products`, `PATCH|DELETE /api/seller/products/:id`
- `GET /api/cart`, `POST|PATCH|DELETE /api/cart/items`
- `GET|DELETE /api/admin/users`

Satıcı uçları session cookie gerektirir ve yalnızca oturum açmış kullanıcının kendi ürünlerini yönetir. Ürün fiyatı, stok, zorunlu alanlar ve sahiplik backend’de doğrulanır.

## Testler

```sh
bundle exec rspec
```

Request spec’leri kayıt, yetkilendirme, ürün sahipliği ve sepet API’sini kapsar. Tam test paketi için test veritabanının migration’ları uygulanmış olmalıdır.
