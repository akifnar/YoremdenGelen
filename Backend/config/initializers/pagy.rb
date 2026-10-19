# Pagy ayarları: https://ddnexus.github.io/pagy/docs/api/pagy
require "pagy/extras/overflow"

# Var olmayan bir sayfa istenirse (ör. ürünler satılıp sayfa sayısı azaldıysa) hata yerine son sayfa gösterilir.
Pagy::DEFAULT[:overflow] = :last_page
# Sayfa bağlantılarında görünen en fazla sayfa numarası (1 … 4 5 [6] 7 8 … 20 gibi).
Pagy::DEFAULT[:size] = 5
