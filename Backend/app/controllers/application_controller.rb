class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_request!

  private

  def permitted_params(allowed_params)
    params.permit(allowed_params)
  end

  def current_user
    @current_user
  end

  def authenticate_request!
    raw_session_token = cookies[:session_token].to_s
    user = User.find_by(session_token: User.token_digest(raw_session_token)) if raw_session_token.present?
    if user&.session_token_expires_at&.future?
      validate_remember_cookie(user)
      @current_user = user
      return
    end

    remember_digest = cookies[:remember_token].to_s
    user = User.find_by(remember_token: remember_digest) if remember_digest.present?
    if user&.remember_token_expires_at&.future?
      refreshed_tokens = user.refresh_session!(remember_digest)
      if refreshed_tokens
        set_auth_cookies(refreshed_tokens, remember_me: true)
        @current_user = user
        return
      end
    end

    render json: { errors: [ "Oturum açmanız gerekiyor" ] }, status: :unauthorized
  end

  def validate_remember_cookie(user)
    remember_digest = cookies[:remember_token].to_s
    return if remember_digest.blank?

    valid = user.remember_token_expires_at&.future? &&
      ActiveSupport::SecurityUtils.secure_compare(user.remember_token.to_s, remember_digest)
    cookies.delete(:remember_token, path: "/") unless valid
  end

  def set_auth_cookies(tokens, remember_me: false)
    common_options = { httponly: true, same_site: :lax, secure: Rails.env.production?, path: "/" }
    cookies[:session_token] = common_options.merge(value: tokens.fetch(:session_token))
    if remember_me && tokens[:remember_token]
      cookies[:remember_token] = common_options.merge(value: tokens.fetch(:remember_token), expires: User::REMEMBER_LIFETIME.from_now)
    else
      cookies.delete(:remember_token, path: "/")
    end
  end

  def clear_auth_cookies
    cookies.delete(:session_token, path: "/")
    cookies.delete(:remember_token, path: "/")
  end
end
