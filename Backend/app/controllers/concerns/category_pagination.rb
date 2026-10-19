# Katalog sayfalaması (Pagy). Anasayfa her kategorinin ilk 6 ürününü bölüm halinde, CategoriesController
# tek kategorinin sayfasını (12'şer), SellersController satıcının ürünlerini gösterir.
module CategoryPagination
  extend ActiveSupport::Concern
  include Pagy::Backend

  SECTION_PER_PAGE = 6   # anasayfadaki kategori bölümü
  PAGE_PER_PAGE = 12     # kategori ve satıcı sayfaları

  private

  # pagy(collection, **vars) -> [Pagy nesnesi, o sayfanın kayıtları (offset/limit uygulanmış Relation)]
  #   count:        Pagy normalde collection.count çalıştırır; popülerlik sıralaması JOIN + ORDER içerdiği
  #                 için sayım sırasız scope üzerinden ayrıca verilir (anasayfada tek GROUP BY sorgusundan gelir).
  #   page:         Controller'da doğrulanmış sayfa numarası (Pagy'nin params'tan okumasına bırakılmaz).
  #   request_path: Pagy bağlantıları varsayılan olarak mevcut URL'e (anasayfada "/") gider; her kategori
  #                 kendi adresine (/kategoriler/:slug?page=N) bağlanır.
  def paginate_category(category, page: 1, count: nil, limit: SECTION_PER_PAGE)
    scope = Product.available.where(category: category)
    pagy(scope.by_popularity.with_attached_main_image,
         count: count || scope.count, limit: limit, page: page,
         request_path: category_path(Product.category_slug(category)))
  end

  # Controller seviyesi doğrulama: yalnızca pozitif tam sayı kabul edilir, aksi halde 1. sayfa.
  # Son sayfadan büyük değerler Pagy'nin overflow ayarıyla son sayfaya çekilir (config/initializers/pagy.rb).
  def requested_page
    page = params[:page].to_s
    page.match?(/\A[1-9]\d{0,5}\z/) ? page.to_i : 1
  end
end
