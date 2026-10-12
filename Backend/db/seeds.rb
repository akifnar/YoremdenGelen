require "faker"

Faker::Config.locale = :en

regional_dishes = [
  [ "Kayseri Mantısı", "İç Anadolu", "El açması hamurun içinde baharatlı kıyma; sarımsaklı yoğurt ve tereyağlı sosla servis edilir." ],
  [ "İzmir Boyozu", "Ege", "Kat kat hamurdan hazırlanan, fırından yeni çıkmış geleneksel İzmir lezzeti." ],
  [ "Gaziantep Baklavası", "Güneydoğu Anadolu", "İnce yufkalar, Antep fıstığı ve şerbetle hazırlanan geleneksel tatlı." ],
  [ "Adana İçli Köfte", "Akdeniz", "Dışı ince bulgurlu, içi baharatlı kıymalı geleneksel içli köfte." ],
  [ "Trabzon Kuymak", "Karadeniz", "Mısır unu, tereyağı ve uzayan yöresel peynirle hazırlanan sıcak lezzet." ],
  [ "Hatay Künefesi", "Akdeniz", "Tel kadayıf ve yöresel peynirle hazırlanan, şerbeti dengeli künefe." ],
  [ "Erzurum Cağ Kebabı", "Doğu Anadolu", "Yatay şişte odun ateşinde pişirilen, ince dilimlenerek sunulan kebap." ],
  [ "Bursa İskender Kebabı", "Marmara", "Pideli döner, domates sosu ve yoğurtla hazırlanan Bursa klasiği." ],
  [ "Nevşehir Testi Kebabı", "İç Anadolu", "Testide ağır ağır pişirilen et ve sebzelerle hazırlanan yöresel kebap." ],
  [ "Antakya Tepsi Kebabı", "Akdeniz", "Zırh kıyması, biber ve yöresel baharatlarla tepside pişirilir." ],
  [ "Konya Etli Ekmek", "İç Anadolu", "İnce hamur üzerine yayılan kıymalı harçla taş fırında pişirilir." ],
  [ "Mardin Kaburga Dolması", "Güneydoğu Anadolu", "Baharatlı iç pilavla doldurulup uzun süre pişirilen geleneksel kuzu kaburga." ],
  [ "Sivas Köftesi", "İç Anadolu", "Dana etinin yöresel yöntemle yoğrulup ızgarada pişirilmesiyle hazırlanır." ],
  [ "Rize Hamsili Pilav", "Karadeniz", "Karadeniz hamsisi ve baharatlı pilavla hazırlanan yöresel yemek." ],
  [ "Şanlıurfa Lahmacunu", "Güneydoğu Anadolu", "İnce hamur üzerinde isotlu ve yöresel baharatlı kıymalı harç." ],
  [ "Tekirdağ Köftesi", "Marmara", "Özel baharat karışımıyla hazırlanan, ızgarada pişmiş yöresel köfte." ],
  [ "Afyon Kaymağı", "Ege", "Afyonkarahisar'ın geleneksel yöntemlerle hazırlanan yoğun kıvamlı manda kaymağı." ],
  [ "Malatya Kayısılı Tatlı", "Doğu Anadolu", "Gün kurusu kayısı ve yöresel ürünlerle hazırlanan hafif tatlı." ],
  [ "Edirne Ciğer Tava", "Marmara", "İnce dilimlenmiş ciğerin kızgın yağda çıtır pişirilmesiyle hazırlanır." ],
  [ "Kars Hangel", "Doğu Anadolu", "El açması hamur, sarımsaklı yoğurt ve tereyağlı sosla servis edilir." ],
  [ "Aydın Çöp Şiş", "Ege", "Küçük et parçalarının şişte köz ateşinde pişirilmesiyle hazırlanır." ],
  [ "Mersin Tantunisi", "Akdeniz", "Sacda kavrulan ince et, lavaş ve yöresel baharatlarla sunulur." ],
  [ "Bolu Mengen Pilavı", "Karadeniz", "Pirinç, mantar ve yöresel malzemelerle hazırlanan Mengen usulü pilav." ],
  [ "Diyarbakır Burma Kadayıfı", "Güneydoğu Anadolu", "İnce tel kadayıf ve cevizle hazırlanan, şerbetle buluşan tatlı." ],
  [ "Kahramanmaraş Dondurması", "Akdeniz", "Salep ve keçi sütüyle geleneksel yöntemle hazırlanan Maraş dondurması." ],
  [ "Çorum Leblebisi", "Karadeniz", "Çorum'un geleneksel kavurma yöntemiyle hazırlanan nohut leblebisi." ],
  [ "Kütahya Cimcik Aşı", "Ege", "Küçük hamur parçaları, yoğurt ve tereyağlı sosla hazırlanan yöresel yemek." ],
  [ "Manisa Mesir Macunu", "Ege", "Çeşitli baharatlarla hazırlanan geleneksel Manisa macunu." ],
  [ "Ordu Pidesi", "Karadeniz", "Yöresel peynir ve tereyağıyla taş fırında pişirilen açık pide." ],
  [ "Balıkesir Höşmerim", "Marmara", "Yöresel peynir, irmik ve şekerle hazırlanan geleneksel tatlı." ]
]

regional_dishes.each_with_index do |(name, _region, description), index|
  category = case name
  when /peynir|kuymak|kaymak|yoğurt/i then "Peynir"
  when /zeytin|zeytinyağı/i then "Zeytin"
  when /baklava|künefe|tatlı|kadayıf|dondurma|kayısı|höşmerim|macunu/i then "Tatlılar"
  when /boyoz|mantı|ekmek|pide|hamsili pilav|hamgel|cimcik|pilav|lahmacun/i then "Hamur İşleri"
  else "Et ve Şarküteri"
  end
  sku = "YGG-LOCAL-%03d" % (index + 1)
  product = Product.find_by(sku: sku) || Product.where(sku: nil).order(:id).first || Product.new
  product.sku = sku
  product.assign_attributes(
    name: name,
    category: category,
    description: description,
    price: Faker::Commerce.price(range: 45.0..650.0, as_string: false),
    stock: Faker::Number.between(from: 8, to: 120),
    is_active: true
  )
  product.save!
end

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
    role: "user"
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
  if is_new_or_migrated_account || (!Rails.env.production? && user.authenticate(legacy_password))
    user.allow_seed_password = !Rails.env.production? && password.length < 8
    user.password = password
  end
  user.email_verified_at ||= Time.current
  user.save!
end
