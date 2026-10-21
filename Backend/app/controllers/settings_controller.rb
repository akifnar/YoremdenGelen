# Profil ayarları. Alıcılar için şimdilik kapalı: yalnızca satıcılar açabilir.
class SettingsController < ApplicationController
  before_action :require_seller!

  def show
    @user = current_user
  end

  # Profil değişiklikleri mevcut şifre ile onaylanır. Controller seviyesi: şifre zorunlu ve bcrypt
  # karşılaştırmasıyla doğrulanır, dosya türü/boyutu erken reddedilir; model seviyesi: User doğrulamaları.
  def update
    @user = current_user
    attributes = settings_params
    password_error = current_password_error
    avatar_error = avatar_error(attributes[:avatar])
    # avatar= kalıcı kayıtta eki save'e kadar bekletir; doğrulama başarısızsa dosya yazılmaz.
    @user.assign_attributes(attributes.except(:current_password, *(avatar_error ? [ :avatar ] : [])))
    @user.errors.add(:base, password_error) if password_error
    @user.errors.add(:avatar, avatar_error) if avatar_error
    return render_invalid if @user.errors.any?
    return render_invalid unless @user.save

    redirect_to settings_path, notice: "Profilin güncellendi.", status: :see_other
  end

  private

  def require_seller!
    require_role!("seller", message: "Ayarlar şimdilik yalnızca satıcı hesaplarına açıktır")
  end

  def current_password_error
    password = settings_params[:current_password].to_s
    return "Değişiklikleri kaydetmek için mevcut şifreni gir" if password.blank?

    "Mevcut şifre hatalı" unless current_user.authenticate(password)
  end

  def avatar_error(upload)
    return if upload.blank?
    return "PNG, JPEG veya WebP olmalıdır" unless upload.respond_to?(:content_type) && User::AVATAR_CONTENT_TYPES.include?(upload.content_type)

    "en fazla 2 MB olabilir" if upload.size > User::AVATAR_MAX_SIZE
  end

  def render_invalid
    @user.restore_attributes([ :name ]) if @user.errors[:base].any?
    render :show, status: :unprocessable_entity
  end

  def settings_params
    @settings_params ||= begin
      # Alıcı yalnızca adını, satıcı adını ve profil resmini değiştirebilir; izin verilmeyen alanlar atılır.
      editable = current_user.seller? ? [ :name, :avatar, :current_password ] : [ :name, :current_password ]
      attributes = permitted_params(user: editable)[:user] || ActionController::Parameters.new
      attributes.delete(:avatar) if attributes[:avatar].blank?
      attributes
    end
  end
end
