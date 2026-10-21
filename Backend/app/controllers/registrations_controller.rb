class RegistrationsController < ApplicationController
  skip_before_action :authenticate_request!
  before_action :reject_authenticated_registration!

  def new
    @user = User.new
  end

  def create
    attributes = registration_params.except(:remember_me).to_h
    attributes["role"] = "buyer"
    @user = User.new(attributes)
    if @user.valid?
      UserRegistrationJob.perform_later(name: @user.name, email: @user.email, password_digest: @user.password_digest)
      message = "Kaydınız alındı. Doğrulama e-postası gönderilecek; e-postanızı doğruladıktan sonra giriş yapabilirsiniz."
      redirect_to login_path, notice: message, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Kayıt, oturum çerezlerini yenilememeli; bu yüzden current_user yerine salt-okunur kontrol yapılır.
  def reject_authenticated_registration!
    raw_session_token = cookies.encrypted[:session_token].to_s
    session_user = User.find_by(session_token: User.token_digest(raw_session_token)) if raw_session_token.present?
    authenticated = session_user&.session_token_expires_at&.future?

    unless authenticated
      raw_remember_token = cookies.encrypted[:remember_token].to_s
      remember_user = User.find_by(remember_token: User.token_digest(raw_remember_token)) if raw_remember_token.present?
      authenticated = remember_user&.remember_token_matches?(raw_remember_token)
    end
    return unless authenticated

    redirect_to root_path, alert: "Zaten giriş yaptınız."
  end

  def registration_params
    permitted_params(user: [ :name, :email, :password, :remember_me ])[:user] || ActionController::Parameters.new
  end
end
