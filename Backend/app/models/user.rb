require "openssl"
require "securerandom"
require "uri"

class User < ApplicationRecord
  has_many :products,
           foreign_key: :seller_id,
           inverse_of: :seller,
           dependent: :nullify

  ROLES = %w[user admin].freeze
  SESSION_LIFETIME = 12.hours
  REMEMBER_LIFETIME = 30.days
  PASSWORD_ITERATIONS = 120_000

  attr_reader :password
  attr_accessor :allow_seed_password

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 8 }, if: -> { password.present? && !allow_seed_password }
  validates :password_digest, presence: true, unless: :google_uid?

  def password=(value)
    @password = value
    return if value.blank?

    salt = SecureRandom.hex(16)
    digest = OpenSSL::PKCS5.pbkdf2_hmac(value, salt, PASSWORD_ITERATIONS, 32, "sha256").unpack1("H*")
    self.password_digest = [ PASSWORD_ITERATIONS, salt, digest ].join("$")
  end

  def authenticate(value)
    return false if password_digest.blank?

    iterations, salt, expected = password_digest.split("$", 3)
    actual = OpenSSL::PKCS5.pbkdf2_hmac(value.to_s, salt, iterations.to_i, 32, "sha256").unpack1("H*")
    ActiveSupport::SecurityUtils.secure_compare(actual, expected) ? self : false
  end

  def issue_session!(remember_me: false)
    raw_session_token = SecureRandom.urlsafe_base64(32)
    raw_remember_token = SecureRandom.urlsafe_base64(48) if remember_me
    update!(
      session_token: self.class.token_digest(raw_session_token),
      session_token_expires_at: SESSION_LIFETIME.from_now,
      remember_token: raw_remember_token && self.class.token_digest(raw_remember_token),
      remember_token_expires_at: raw_remember_token && REMEMBER_LIFETIME.from_now
    )
    {
      session_token: raw_session_token,
      remember_token: raw_remember_token && self.class.token_digest(raw_remember_token)
    }
  end

  def refresh_session!(remember_digest)
    return false if remember_token.blank? || remember_token_expires_at.blank? || remember_token_expires_at <= Time.current
    return false unless ActiveSupport::SecurityUtils.secure_compare(remember_token, remember_digest.to_s)

    raw_session_token = SecureRandom.urlsafe_base64(32)
    raw_remember_token = SecureRandom.urlsafe_base64(48)
    update!(
      session_token: self.class.token_digest(raw_session_token),
      session_token_expires_at: SESSION_LIFETIME.from_now,
      remember_token: self.class.token_digest(raw_remember_token),
      remember_token_expires_at: REMEMBER_LIFETIME.from_now
    )
    {
      session_token: raw_session_token,
      remember_token: self.class.token_digest(raw_remember_token)
    }
  end

  def self.token_digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def revoke_tokens!
    update!(session_token: nil, session_token_expires_at: nil, remember_token: nil, remember_token_expires_at: nil)
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

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
