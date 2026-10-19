class ApplicationController < ActionController::Base
  # Turbo Stream hedefleri için dom_id (ör. "reactions_comment_5").
  include ActionView::RecordIdentifier

  # Tüm durum değiştiren istekler authenticity token ile korunur (formlar ve Stimulus fetch'leri X-CSRF-Token gönderir).
  protect_from_forgery with: :exception

  # Sayfa geçişleri <turbo-frame id="main"> üzerinden gelir; bu isteklerde header/footer'sız
  # layouts/main_frame kullanılır. Diğer frame istekleri turbo-rails'in varsayılanıyla render edilir.
  layout -> do
    if turbo_frame_request_id == "main" then "main_frame"
    elsif turbo_frame_request? then "turbo_rails/frame"
    else "application"
    end
  end

  before_action :authenticate_request!

  helper_method :current_user, :current_cart

  private

  def permitted_params(allowed_params)
    params.permit(allowed_params)
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = user_from_session_cookie || user_from_remember_cookie
  end

  def authenticate_request!
    return if current_user

    respond_to do |format|
      format.html { redirect_to_login }
      format.any { redirect_to_login }
    end
  end

  # Rol bazlı yetkilendirme (controller seviyesi); User::ROLES model seviyesinde ayrıca doğrulanır.
  def require_role!(*roles, message:)
    return if roles.include?(current_user&.role)

    respond_to do |format|
      format.html { redirect_to root_path, alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("notifications", partial: "shared/notice", locals: { message: message, error: true }),
               status: :forbidden
      end
      format.any { head :forbidden }
    end
  end

  # Turbo isteklerinde hata bildirimi olarak, tam sayfa isteklerde geri yönlendirme ile gösterilir.
  def respond_with_error(message, status, fallback: root_path)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("notifications", partial: "shared/notice", locals: { message: message, error: true }),
               status: status
      end
      format.html { redirect_back fallback_location: fallback, alert: message, status: :see_other }
    end
  end

  def redirect_to_login
    redirect_to login_path(returnTo: return_path_for_login), alert: "Devam etmek için giriş yapın."
  end

  def return_path_for_login
    return request.fullpath if request.get?

    URI(request.referer.to_s).path.presence || root_path
  rescue URI::InvalidURIError
    root_path
  end

  # Auth cookie'leri şifreli (cookies.encrypted, AES-256-GCM) tutulur: tarayıcı yalnızca okunamayan ve
  # değiştirilemeyen bir değer görür. Çözülen ham token SHA-256'dan geçirilip DB'deki özetle karşılaştırılır.
  def user_from_session_cookie
    raw_session_token = cookies.encrypted[:session_token].to_s
    return if raw_session_token.blank?

    user = User.find_by(session_token: User.token_digest(raw_session_token))
    return unless user&.session_token_expires_at&.future?

    validate_remember_cookie(user)
    user
  end

  def user_from_remember_cookie
    raw_remember_token = cookies.encrypted[:remember_token].to_s
    return if raw_remember_token.blank?

    user = User.find_by(remember_token: User.token_digest(raw_remember_token))
    refreshed_tokens = user&.refresh_session!(raw_remember_token)
    return unless refreshed_tokens

    set_auth_cookies(refreshed_tokens, remember_me: true)
    user
  end

  def validate_remember_cookie(user)
    raw_remember_token = cookies.encrypted[:remember_token].to_s
    return if raw_remember_token.blank?

    cookies.delete(:remember_token, path: "/") unless user.remember_token_matches?(raw_remember_token)
  end

  def set_auth_cookies(tokens, remember_me: false)
    common_options = { httponly: true, same_site: :lax, secure: Rails.env.production?, path: "/" }
    cookies.encrypted[:session_token] = common_options.merge(value: tokens.fetch(:session_token))
    if remember_me && tokens[:remember_token]
      cookies.encrypted[:remember_token] = common_options.merge(value: tokens.fetch(:remember_token), expires: User::REMEMBER_LIFETIME.from_now)
    else
      cookies.delete(:remember_token, path: "/")
    end
  end

  def clear_auth_cookies
    cookies.delete(:session_token, path: "/")
    cookies.delete(:remember_token, path: "/")
  end

  # Sepet doğrudan kullanıcıya bağlıdır (carts.user_id); hangi cihazdan girilirse girilsin aynı sepet açılır.
  # Yalnızca alıcıların sepeti vardır: satıcı ve admin ürün almak için alıcı hesabı kullanır.
  def current_cart
    return @current_cart if defined?(@current_cart)

    @current_cart = (Cart.for(current_user) if current_user&.buyer?)
  end

  def safe_return_path(path)
    path = path.to_s
    path.start_with?("/") && !path.start_with?("//") ? path : root_path
  end
end
