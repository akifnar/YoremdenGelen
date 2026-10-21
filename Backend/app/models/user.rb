require "openssl"
require "securerandom"
require "uri"

class User < ApplicationRecord
  has_many :products,
           foreign_key: :seller_id,
           inverse_of: :seller,
           dependent: :nullify

  has_one :cart, dependent: :destroy
  has_many :product_purchases, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :avatar

  ROLES = %w[buyer seller admin].freeze
  # Oturum token'ı sabit bir ömürle değil hareketsizlikle düşer: kullanıldıkça süresi yenilenir (touch_session!).
  # Cookie'nin kendisi süresizdir (tarayıcı oturum cookie'si): tarayıcı kapanınca silinir.
  SESSION_IDLE_TIMEOUT = 12.hours
  REMEMBER_LIFETIME = 30.days
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_MAX_SIZE = 2.megabytes

  # Şifre bcrypt ile hash'lenip password_digest'te saklanır; authenticate gelen şifreyi aynı hash'ten
  # geçirip karşılaştırır. Doğrulamalar aşağıda kendimiz tanımlandığı için varsayılanlar kapalı.
  has_secure_password validations: false
  attr_accessor :allow_seed_password

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES, message: "geçerli bir rol değil" }
  validates :password, length: { minimum: 8 }, if: -> { password.present? && !allow_seed_password }
  validates :password, length: { maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED }, allow_nil: true
  validate :avatar_is_a_small_image, if: -> { avatar.attached? }
  validates :password_digest, presence: true, unless: :google_uid?
  validate :seller_with_active_products_keeps_role, if: :will_save_change_to_role?

  ROLES.each do |role_name|
    define_method(:"#{role_name}?") { role == role_name }
  end

  # Ham token'lar yalnızca (şifreli) cookie'ye yazılır; veritabanında SHA-256 özetleri tutulur.
  # Böylece veritabanı sızsa bile cookie üretilemez.
  def issue_session!(remember_me: false)
    raw_session_token = SecureRandom.urlsafe_base64(32)
    raw_remember_token = SecureRandom.urlsafe_base64(48) if remember_me
    update!(
      session_token: self.class.token_digest(raw_session_token),
      session_token_expires_at: SESSION_IDLE_TIMEOUT.from_now,
      remember_token: raw_remember_token && self.class.token_digest(raw_remember_token),
      remember_token_expires_at: raw_remember_token && REMEMBER_LIFETIME.from_now
    )
    { session_token: raw_session_token, remember_token: raw_remember_token }
  end

  # Kayan süre: her geçerli istekte oturumun bitişi şimdi + 12 saate taşınır. Her istekte yazmamak için yalnızca
  # sürenin yarısından azı kaldıysa güncellenir; doğrulama ve callback'ler atlanır (tek UPDATE).
  def touch_session!
    return if session_token_expires_at.blank? || session_token_expires_at > (SESSION_IDLE_TIMEOUT / 2).from_now

    update_column(:session_token_expires_at, SESSION_IDLE_TIMEOUT.from_now)
  end

  def remember_token_matches?(raw_remember_token)
    remember_token.present? && remember_token_expires_at&.future? &&
      ActiveSupport::SecurityUtils.secure_compare(remember_token, self.class.token_digest(raw_remember_token))
  end

  def refresh_session!(raw_remember_token)
    return false unless remember_token_matches?(raw_remember_token)

    issue_session!(remember_me: true)
  end

  def self.token_digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def revoke_tokens!
    update!(session_token: nil, session_token_expires_at: nil, remember_token: nil, remember_token_expires_at: nil)
  end

  # Ürün sayfasında yorum formunu ve puan alanını belirler: nil ise yorum yetkisi yoktur, satır varsa
  # rated? ile ilk yorum olup olmadığı anlaşılır. Alıcı dışındaki roller için sorgu çalışmaz.
  def purchase_of(product)
    return unless buyer?

    product_purchases.find_by(product_id: product.id)
  end

  def issue_email_verification!
    update!(email_verification_token: SecureRandom.urlsafe_base64(32), email_verification_expires_at: 10.minutes.from_now)
  end

  def verify_email!(token)
    return false if email_verified_at? || email_verification_expires_at.blank? || email_verification_expires_at <= Time.current
    return false unless ActiveSupport::SecurityUtils.secure_compare(email_verification_token.to_s, token.to_s)

    update!(email_verified_at: Time.current, email_verification_token: nil, email_verification_expires_at: nil)
  end

  private

  def avatar_is_a_small_image
    errors.add(:avatar, "PNG, JPEG veya WebP olmalıdır") unless AVATAR_CONTENT_TYPES.include?(avatar.content_type)
    errors.add(:avatar, "en fazla 2 MB olabilir") if avatar.byte_size.to_i > AVATAR_MAX_SIZE
  end

  # Yayındaki ürünleri sahipsiz (satıcı paneline erişemeyen) kalmasın diye önce ürünler kaldırılmalı.
  def seller_with_active_products_keeps_role
    return unless role_was == "seller" && products.active.exists?

    errors.add(:role, "yayında ürünü olan satıcı için değiştirilemez; önce ürünleri yayından kaldırın")
  end

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
