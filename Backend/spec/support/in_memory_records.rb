# Veritabanına yazmadan "kaydedilmiş" görünen ActiveRecord nesneleri ve sorgu double'ları.
# `instantiate` gerçek bir DB satırından yükleniyormuş gibi nesne kurar: id, dom_id, rota yardımcıları ve
# model doğrulamaları çalışır, ama INSERT yapılmaz.
module InMemoryRecords
  SESSION_TOKEN = "stubbed-session-token".freeze

  # column_defaults ile birleştirilir; aksi halde yüklenmeyen kolonlar MissingAttributeError verir.
  def persisted_user(id: 1001, role: "buyer", **attributes)
    User.instantiate(User.column_defaults.merge(
      "id" => id, "name" => "Kullanıcı #{id}", "email" => "user#{id}@example.com", "role" => role,
      "password_digest" => "120000$salt$digest", "email_verified_at" => Time.current
    ).merge(attributes.stringify_keys))
  end

  def persisted_product(id: 2001, **attributes)
    Product.instantiate(Product.column_defaults.merge(
      "id" => id, "name" => "Ezine Peyniri #{id}", "description" => "Tam yağlı", "category" => "Peynir",
      "price" => "150.0", "stock" => 4, "is_active" => true
    ).merge(attributes.stringify_keys))
  end

  # İlişkiyi sorgu çalıştırmadan doldurur (has_one atamasının kayıt yapmasını da önler).
  def preload_association(record, name, target)
    record.association(name).target = target
    record
  end

  # Scope / with_attached_* / includes / order zincirlerini verilen kayıtlarla yanıtlayan Relation double'ı.
  def relation_double(records = [])
    relation = double("ActiveRecord::Relation", to_a: records, to_ary: records, size: records.size,
                                                  empty?: records.empty?, any?: records.any?)
    %i[active available with_attached_main_image with_attached_gallery_images includes order select].each do |method|
      allow(relation).to receive(method).and_return(relation)
    end
    allow(relation).to receive(:each) { |&block| records.each(&block) }
    relation
  end

  # ProductsController#find_active_product! zincirini (Product.active...find) bellekteki ürünlere bağlar.
  def stub_active_product_lookup(*products)
    relation = relation_double
    allow(relation).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
    products.each { |product| allow(relation).to receive(:find).with(product.id.to_s).and_return(product) }
    allow(Product).to receive(:active).and_return(relation)
    # Header menüsünün kategori sayımı (Product.available.group.count) sorgusuz boş sonuç döner.
    allow(Product).to receive(:available).and_return(Product.none)
    relation
  end

  # Oturumu DB'ye yazmadan açar: session_token çerezi bellekteki kullanıcıya çözülür. Header'daki
  # sepet rozeti için kullanıcının sepeti de bellekte tutulur; gerçek sepet gereken testler stub_cart: false verir.
  def sign_in_stubbed(user, stub_cart: true)
    user.session_token_expires_at = User::SESSION_IDLE_TIMEOUT.from_now
    allow(User).to receive(:find_by).and_call_original
    allow(User).to receive(:find_by).with(session_token: User.token_digest(SESSION_TOKEN)).and_return(user)
    allow(Cart).to receive(:for).with(user).and_return(Cart.instantiate(Cart.column_defaults.merge("id" => user.id, "user_id" => user.id))) if stub_cart
    set_encrypted_cookie(:session_token, SESSION_TOKEN)
    user
  end
end

RSpec.configure do |config|
  config.include InMemoryRecords
end
