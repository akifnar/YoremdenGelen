require "net/http"
require "json"

class SessionsController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :new, :create, :google ]
  # Google Identity Services "login_uri" akışı formu Google'dan POST eder; kendi
  # double-submit CSRF kontrolünü (g_csrf_token) verify_google_csrf! ile yapıyoruz.
  skip_forgery_protection only: :google
  before_action :verify_google_csrf!, only: :google

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

  def google
    claims = google_claims
    return login_failed("Google kimliği doğrulanamadı", :unauthorized) unless claims && claims["email_verified"] == "true"

    user = User.find_or_initialize_by(google_uid: claims.fetch("sub"))
    user.assign_attributes(name: claims["name"].presence || claims["email"], email: claims["email"], email_verified_at: Time.current)
    user.save!
    set_auth_cookies(user.issue_session!)
    redirect_to safe_return_path(params[:returnTo]), notice: "Hoş geldin, #{user.name}!"
  rescue ActiveRecord::RecordInvalid => error
    login_failed(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
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
    permitted_params([ :credential ])
  end

  def verify_google_csrf!
    cookie_token = cookies[:g_csrf_token].to_s
    param_token = params[:g_csrf_token].to_s
    return if cookie_token.present? && ActiveSupport::SecurityUtils.secure_compare(cookie_token, param_token)

    login_failed("Google oturum isteği doğrulanamadı", :unprocessable_entity)
  end

  def google_claims
    client_id = ENV["GOOGLE_CLIENT_ID"]
    return if client_id.blank? || google_params[:credential].blank?

    uri = URI("https://oauth2.googleapis.com/tokeninfo?id_token=#{URI.encode_www_form_component(google_params[:credential])}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 3) { |http| http.get(uri.request_uri) }
    return unless response.is_a?(Net::HTTPSuccess)

    claims = JSON.parse(response.body)
    claims if claims["aud"] == client_id && claims["exp"].to_i > Time.current.to_i
  rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error
    nil
  end
end
