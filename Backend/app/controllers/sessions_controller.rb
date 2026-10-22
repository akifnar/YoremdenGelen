require "net/http"
require "json"

class SessionsController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :new, :create, :google_start, :google ]

  # OAuth 2.0 "authorization code" akışı: düğme bizim (temaya uygun), Google'a yönlendirme ve dönüş tam sayfa
  # GET geçişi olduğu için Lax cookie'ler gönderilir; state ve dönüş yolu şifreli bu cookie'de bekler.
  GOOGLE_STATE_COOKIE = :google_oauth
  GOOGLE_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth".freeze
  GOOGLE_TOKEN_URI = URI("https://oauth2.googleapis.com/token").freeze
  GOOGLE_ISSUERS = %w[https://accounts.google.com accounts.google.com].freeze

  def new
    @return_to = safe_return_path(params[:returnTo])
  end

  def create
    user = User.find_by(email: login_params[:email].to_s.strip.downcase)
    return login_failed("E-posta veya şifre hatalı", :unauthorized) unless user&.authenticate(login_params[:password])
    return login_failed("E-posta adresinizi doğrulayın", :forbidden) unless user.email_verified_at?

    remember_me = ActiveModel::Type::Boolean.new.cast(login_params[:remember_me])
    tokens = user.issue_session!(remember_me: remember_me)
    set_auth_cookies(tokens, remember_me: remember_me)
    redirect_to safe_return_path(params[:returnTo]), notice: "Hoş geldin, #{user.name}!"
  end

  # Giriş ve kayıt sayfasındaki Google düğmesi buraya POST eder (CSRF korumalı); kullanıcı Google'a gönderilir.
  def google_start
    state = SecureRandom.urlsafe_base64(32)
    cookies.encrypted[GOOGLE_STATE_COOKIE] = {
      value: { "state" => state, "return_to" => safe_return_path(params[:returnTo]) }.to_json,
      httponly: true, same_site: :lax, secure: Rails.env.production?, expires: 10.minutes.from_now
    }
    query = { client_id: ENV["GOOGLE_CLIENT_ID"], redirect_uri: google_auth_url, response_type: "code",
              scope: "openid email profile", state: state, prompt: "select_account" }
    redirect_to "#{GOOGLE_AUTHORIZE_URL}?#{query.to_query}", allow_other_host: true, status: :see_other
  end

  # Google Console'daki yetkili redirect URI (/auth/google). Hesap yoksa oluşturulur: giriş ve kayıt aynı adımdır.
  def google
    stored = google_state_cookie
    cookies.delete(GOOGLE_STATE_COOKIE)
    unless stored && ActiveSupport::SecurityUtils.secure_compare(stored["state"].to_s, google_params[:state].to_s)
      return google_failed("Google oturum isteği doğrulanamadı")
    end
    return google_failed("Google girişi iptal edildi") if google_params[:error].present?

    claims = google_claims(google_params[:code])
    return google_failed("Google kimliği doğrulanamadı") unless claims && claims["email_verified"].to_s == "true"

    user = User.find_or_initialize_by(google_uid: claims.fetch("sub"))
    user.assign_attributes(name: claims["name"].presence || claims["email"], email: claims["email"], email_verified_at: Time.current)
    user.save!
    set_auth_cookies(user.issue_session!)
    redirect_to safe_return_path(stored["return_to"]), notice: "Hoş geldin, #{user.name}!", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    google_failed(error.record.errors.full_messages.to_sentence)
  end

  def destroy
    current_user.revoke_tokens!
    clear_auth_cookies
    redirect_to root_path, notice: "Çıkış yapıldı.", status: :see_other
  end

  private

  def login_failed(message, status)
    @return_to = safe_return_path(params[:returnTo])
    @email = login_params[:email]
    flash.now[:alert] = message
    render :new, status: status
  end

  def login_params
    permitted_params(user: [ :email, :password, :remember_me ])[:user] || ActionController::Parameters.new
  end

  def google_params
    permitted_params([ :code, :state, :error ])
  end

  def google_failed(message)
    redirect_to login_path(returnTo: google_state_cookie&.dig("return_to")), alert: message, status: :see_other
  end

  def google_state_cookie
    @google_state_cookie ||= JSON.parse(cookies.encrypted[GOOGLE_STATE_COOKIE].to_s)
  rescue JSON::ParserError
    nil
  end

  # Kod, client secret ile id_token'a çevrilir. Token doğrudan Google'dan TLS üzerinden geldiği için imza
  # ayrıca doğrulanmaz (OpenID Connect Core 3.1.3.7); alıcı (aud), yayıncı (iss) ve süre kontrol edilir.
  def google_claims(code)
    client_id = ENV["GOOGLE_CLIENT_ID"]
    return if client_id.blank? || ENV["GOOGLE_CLIENT_SECRET"].blank? || code.blank?

    response = Net::HTTP.start(GOOGLE_TOKEN_URI.host, GOOGLE_TOKEN_URI.port, use_ssl: true, open_timeout: 3, read_timeout: 3) do |http|
      http.post(GOOGLE_TOKEN_URI.path, URI.encode_www_form(code: code, client_id: client_id, client_secret: ENV["GOOGLE_CLIENT_SECRET"],
                                                           redirect_uri: google_auth_url, grant_type: "authorization_code"))
    end
    return unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body)["id_token"].to_s.split(".")[1]
    claims = JSON.parse(Base64.urlsafe_decode64(payload.to_s))
    claims if claims["aud"] == client_id && GOOGLE_ISSUERS.include?(claims["iss"]) && claims["exp"].to_i > Time.current.to_i
  rescue JSON::ParserError, ArgumentError, IOError, SystemCallError, Timeout::Error
    nil
  end
end
