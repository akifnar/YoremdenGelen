require "net/http"
require "json"

class Api::AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :register, :login, :google, :verify_email ]
  before_action :reject_authenticated_registration!, only: :register

  def register
    permitted_registration_params = registration_params
    remember_me = ActiveModel::Type::Boolean.new.cast(permitted_registration_params[:remember_me])
    attributes = permitted_registration_params.except(:remember_me).to_h
    attributes["role"] = "user"
    user = User.new(attributes)
    if user.save
      user.issue_email_verification!
      tokens = user.issue_session!(remember_me: remember_me)
      set_auth_cookies(tokens, remember_me: remember_me)
      VerificationMailerJob.perform_later(user.id)
      render json: {
        message: "Doğrulama e-postası gönderildi",
        user: { id: user.id, name: user.name, email: user.email, role: user.role }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: login_params[:email].to_s.strip.downcase)
    return render json: { errors: [ "E-posta veya şifre hatalı" ] }, status: :unauthorized unless user&.authenticate(login_params[:password])
    return render json: { errors: [ "E-posta adresinizi doğrulayın" ] }, status: :forbidden unless user.email_verified_at?

    remember_me = ActiveModel::Type::Boolean.new.cast(login_params[:remember_me])
    tokens = user.issue_session!(remember_me: remember_me)
    set_auth_cookies(tokens, remember_me: remember_me)
    render json: user_payload(user)
  end

  def google
    claims = google_claims
    return render json: { errors: [ "Google kimliği doğrulanamadı" ] }, status: :unauthorized unless claims && claims["email_verified"] == "true"

    user = User.find_or_initialize_by(google_uid: claims.fetch("sub"))
    user.assign_attributes(name: claims["name"].presence || claims["email"], email: claims["email"], email_verified_at: Time.current)
    user.save!
    tokens = user.issue_session!
    set_auth_cookies(tokens)
    render json: user_payload(user)
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def refresh
    render json: user_payload(current_user)
  end

  def logout
    current_user.revoke_tokens!
    clear_auth_cookies
    head :no_content
  end

  def verify_email
    user = User.find_by(email_verification_token: verification_params[:token])
    return render json: { errors: [ "Doğrulama bağlantısı geçersiz veya süresi dolmuş" ] }, status: :unprocessable_entity unless user&.verify_email!(verification_params[:token])

    render json: { message: "E-posta adresi doğrulandı" }
  end

  private

  def reject_authenticated_registration!
    session_token = cookies[:session_token].to_s
    session_user = User.find_by(session_token: User.token_digest(session_token)) if session_token.present?
    authenticated = session_user&.session_token_expires_at&.future?

    unless authenticated
      remember_digest = cookies[:remember_token].to_s
      remember_user = User.find_by(remember_token: remember_digest) if remember_digest.present?
      authenticated = remember_user&.remember_token_expires_at&.future?
    end

    render json: { errors: [ "Zaten giriş yaptınız" ] }, status: :forbidden if authenticated
  end

  def registration_params
    permitted_params(user: [ :name, :email, :password, :remember_me ])[:user] || ActionController::Parameters.new
  end

  def login_params
    permitted_params(user: [ :email, :password, :remember_me ])[:user] || ActionController::Parameters.new
  end

  def verification_params
    permitted_params([ :token ])
  end

  def google_params
    permitted_params([ :credential ])
  end

  def user_payload(user)
    { user: { id: user.id, name: user.name, email: user.email, role: user.role } }
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
