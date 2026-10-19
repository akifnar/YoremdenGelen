if Rails.env.production?
  %w[INITIAL_USER_EMAIL INITIAL_USER_PASSWORD INITIAL_ADMIN_EMAIL INITIAL_ADMIN_PASSWORD].each do |key|
    raise "Set #{key} before seeding production accounts" if ENV[key].blank?
  end
end

initial_accounts = [
  {
    name: "Initial User",
    email: ENV["INITIAL_USER_EMAIL"].presence || "user@mail.com",
    password: ENV["INITIAL_USER_PASSWORD"],
    development_password: "user12345",
    legacy_email: "user@yoremden-gelen.local",
    role: "buyer"
  },
  {
    name: "Initial Admin",
    email: ENV["INITIAL_ADMIN_EMAIL"].presence || "admin@mail.com",
    password: ENV["INITIAL_ADMIN_PASSWORD"],
    development_password: "admin12345",
    legacy_email: "admin@yoremden-gelen.local",
    role: "admin"
  }
]

initial_accounts.each do |attributes|
  password = attributes[:password]
  if password.blank?
    raise "Set INITIAL_#{attributes[:role].upcase}_PASSWORD before seeding production accounts" if Rails.env.production?

    password = attributes[:development_password]
  end

  if Rails.env.production? && password.length < 8
    raise "Initial account passwords must contain at least 8 characters in production"
  end

  user = User.find_by(email: attributes[:email]) || User.find_by(email: attributes[:legacy_email]) || User.new
  is_new_or_migrated_account = user.new_record? || user.email != attributes[:email]
  user.email = attributes[:email]
  user.name = attributes[:name]
  user.role = attributes[:role]
  legacy_password = attributes[:role] == "admin" ? "admin" : "user"
  # Eski (bcrypt öncesi PBKDF2) özetler BCrypt tarafından okunamaz; geliştirmede yeniden belirlenir.
  legacy_digest = begin
    user.password_digest.present? && user.authenticate(legacy_password).present?
  rescue BCrypt::Errors::InvalidHash
    true
  end
  if is_new_or_migrated_account || (!Rails.env.production? && legacy_digest)
    user.allow_seed_password = !Rails.env.production? && password.length < 8
    user.password = password
  end
  user.email_verified_at ||= Time.current
  user.save!
end

# Geliştirme/demo verisi (Faker): 10 satıcı × 10 ürün ve 50 alıcı. Tüm demo hesaplarının şifresi "password123".
# Üretimde çalışmaz; Faker yalnızca development/test grubunda yüklüdür.
unless Rails.env.production?
  require "faker"

  Faker::Config.locale = :tr
  Faker::Config.random = Random.new(42) # Her seed aynı veriyi üretir.
  demo_password = "password123"

  regions = %w[Ezine Bergama Ayvalık Gemlik Kars Erzurum Afyon Kayseri Tokat Malatya Gaziantep Hatay Rize Trabzon
               Bolu Safranbolu Kastamonu Konya Antakya Mardin Edremit Bayramiç Tire Ödemiş Çorum Amasya]
  items_by_category = {
    "Peynir" => [ "Tulum Peyniri", "Kaşar Peyniri", "Örgü Peyniri", "Çökelek", "Lor Peyniri", "Keçi Peyniri" ],
    "Zeytin" => [ "Siyah Zeytin", "Yeşil Zeytin", "Kırma Zeytin", "Çizik Zeytin" ],
    "Zeytinyağı" => [ "Erken Hasat Zeytinyağı", "Sızma Zeytinyağı", "Taş Baskı Zeytinyağı" ],
    "Et ve Şarküteri" => [ "Kangal Sucuk", "Pastırma", "Kavurma", "Kuru Et" ],
    "Tatlılar" => [ "Lokum", "Pestil", "Cevizli Sucuk", "Tahin Helvası", "Kuru Kayısı Tatlısı" ],
    "Hamur İşleri" => [ "Erişte", "Tarhana", "Yufka", "Kuru Mantı", "Bazlama" ],
    "Süt Ürünleri" => [ "Köy Tereyağı", "Süzme Yoğurt", "Manda Kaymağı" ],
    "Diğer Yöresel Ürünler" => [ "Dut Pekmezi", "Çiçek Balı", "Kestane Balı", "Gün Kurusu Kayısı", "Nar Ekşisi" ]
  }
  product_pool = regions.product(items_by_category.to_a).map { |region, (category, items)| [ region, category, items ] }
                        .flat_map { |region, category, items| items.map { |item| [ "#{region} #{item}", category, region, item ] } }
                        .shuffle(random: Faker::Config.random)

  10.times do |index|
    seller = User.find_or_initialize_by(email: "satici#{index + 1}@yoremdengelen.test")
    seller.assign_attributes(
      name: Faker::Name.name,
      role: "seller",
      email_verified_at: Time.current
    )
    seller.password = demo_password if seller.new_record?
    seller.save!

    product_pool.shift(10).each do |name, category, region, item|
      product = Product.find_or_initialize_by(name: name)
      product.assign_attributes(
        seller: seller,
        category: category,
        description: "#{region} yöresinden, #{seller.name} tarafından hazırlanan #{item.downcase(:turkic)}. #{Faker::Lorem.sentence(word_count: 8)}",
        price: Faker::Commerce.price(range: 45.0..650.0, as_string: false),
        # Satıcı 1'in ürünleri yorum yazacak alıcılara satılacağı için hepsi stoklu.
        stock: Faker::Number.between(from: index.zero? ? 20 : 0, to: 120),
        is_active: true
      )
      product.save!

      # Puan ve yorum sayıları aşağıdaki gerçek siparişlerden ve yorumlardan gelir; burada yalnızca ziyaret metrikleri.
      product.metrics.update!(
        click_count: Faker::Number.between(from: 0, to: 800),
        hover_count: Faker::Number.between(from: 0, to: 3_000)
      )
    end
  end

  50.times do |index|
    buyer = User.find_or_initialize_by(email: "alici#{index + 1}@yoremdengelen.test")
    buyer.assign_attributes(name: Faker::Name.name, role: "buyer", email_verified_at: Time.current)
    buyer.password = demo_password if buyer.new_record?
    buyer.save!
  end

  # Örnek siparişler ve yorumlar (yalnızca boş veritabanında): ilk 10 alıcı gerçek sepet → sipariş akışıyla
  # (Checkout) satıcı 1'in ürünlerinden 3'er ürün alır; böylece bu 10 alıcı satıcı 1'in ürünlerine yorum yazabilir.
  # i. alıcı i. ve (i+1). ürüne birer yorum (puanla) yazar: satıcı 1'in her ürününde 2'şer yorum olur.
  # Satıcı bazılarına cevap verir, diğer alıcılar like/dislike bırakır. Sayılar gerçek kayıtlardan oluşur.
  if Order.none?
    comment_texts = [
      "Tam anlatıldığı gibi, çok taze geldi.", "Ailece bayıldık, tekrar sipariş vereceğim.",
      "Paketleme özenliydi, lezzeti yerinde.", "Fiyatına göre gayet iyi.", "Beklediğimden biraz farklıydı ama güzeldi.",
      "Köydeki tadı aynen, teşekkürler!", "Hızlı geldi, kalitesi yüksek."
    ]
    reply_texts = [ "Güzel yorumunuz için teşekkür ederiz!", "Afiyet olsun, yine bekleriz.", "Geri bildiriminiz bizim için çok değerli." ]
    random = Faker::Config.random
    first_seller = User.find_by!(email: "satici1@yoremdengelen.test")
    seller_products = first_seller.products.available.order(:id).to_a
    buyers = User.where(role: "buyer").where("email LIKE ?", "alici%@yoremdengelen.test").order(:id).first(10)

    buyers.each_with_index do |buyer, index|
      purchased = seller_products.rotate(index).first(3)
      cart = Cart.for(buyer)
      purchased.each { |product| cart.cart_items.create!(product: product, quantity: 1) }
      Checkout.new(cart).place!

      purchased.first(2).each do |product|
        Comment.transaction do
          product.comments.create!(user: buyer, body: comment_texts.sample(random: random))
          buyer.purchase_of(product).rate!(random.rand(3..5))
        end
      end
    end

    Comment.top_level.includes(product: :seller).find_each do |comment|
      seller = comment.product.seller
      comment.create_reply!(product: comment.product, user: seller, body: reply_texts.sample(random: random)) if seller && random.rand < 0.4
      buyers.sample(3, random: random).each do |buyer|
        next if buyer.id == comment.user_id

        CommentReaction.toggle!(comment: comment, user: buyer, kind: random.rand < 0.8 ? "like" : "dislike")
      end
    end
  end

  puts "Seed tamam: #{User.where(role: "seller").count} satıcı, #{User.where(role: "buyer").count} alıcı, #{Product.count} ürün, " \
       "#{Order.count} sipariş, #{Comment.top_level.count} yorum, #{Comment.where.not(parent_id: nil).count} satıcı cevabı. Demo şifresi: #{demo_password}"
end
