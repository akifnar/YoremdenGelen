# Rails uygulaması

Bu dizin Yöremden Gelen'in Rails + Hotwire uygulamasını içerir. Docker Compose kurulumu, ortam değişkenleri ve geliştirme hesapları için depo kökündeki [`README.md`](../README.md) dosyasına bakın.

## Yerel komutlar

```sh
bin/setup        # bundle install, db:prepare ve bin/dev
bin/dev          # Rails sunucusu + Tailwind watcher (Procfile.dev)
bin/ci           # RuboCop, bundler-audit ve Brakeman
bundle exec rspec
```

Veritabanı bağlantısı `DB_HOST`, `DB_USERNAME` ve `DB_PASSWORD` ortam değişkenlerinden okunur.

## Başlıca adresler

| Yol | Sayfa |
| --- | --- |
| `/`, `/urunler/:id`, `/kategoriler/:slug`, `/saticilar/:id` | Katalog, ürün, kategori ve satıcı sayfaları |
| `/login`, `/register`, `/verify-email` | Oturum, kayıt ve e-posta doğrulama |
| `/sepet`, `/sepet/siparis` | Sepet ve sipariş |
| `/satici`, `/satici/urunler` | Satıcı paneli ve ürün yönetimi |
| `/admin/users` | Admin kullanıcı yönetimi |
| `/ayarlar` | Satıcı profil ayarları |

Ürün fiyatı, stok, zorunlu alanlar, roller ve ürün sahipliği sunucu tarafında doğrulanır.
