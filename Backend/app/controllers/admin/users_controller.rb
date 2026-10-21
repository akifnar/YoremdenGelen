class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!
  before_action :find_user, only: [ :update, :destroy ]

  rescue_from ActiveRecord::RecordNotFound do
    user_error("Kullanıcı bulunamadı", :not_found)
  end

  def index
    @users = User.order(:id).select(:id, :name, :email, :role, :created_at)
    @new_user = User.new
  end

  # Admin'in eklediği hesaplar e-posta doğrulaması beklemeden aktif olur.
  # Controller seviyesi: zorunlu alanlar ve rol listesi; model seviyesi: User doğrulamaları.
  def create
    attributes = new_user_params
    @new_user = User.new(attributes.merge(email_verified_at: Time.current))
    missing = { name: "Ad", email: "E-posta", password: "Şifre", role: "Rol" }.select { |key, _| attributes[key].blank? }.values
    @new_user.errors.add(:base, "Zorunlu alanlar boş bırakılamaz: #{missing.join(", ")}") if missing.any?
    @new_user.errors.add(:base, "Geçersiz rol: #{attributes[:role]}") if attributes[:role].present? && User::ROLES.exclude?(attributes[:role])
    return render_new_user_invalid if @new_user.errors.any? || !@new_user.save

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("admin_users", partial: "admin/users/user", locals: { user: @new_user }),
          turbo_stream.replace("admin_new_user_form", partial: "admin/users/form", locals: { user: User.new }),
          turbo_stream.append("notifications", partial: "shared/notice", locals: { message: "#{@new_user.name} eklendi.", error: false })
        ], status: :created
      end
      format.html { redirect_to admin_users_path, notice: "Kullanıcı eklendi.", status: :see_other }
    end
  end

  # Rol ataması yalnızca admin tarafından yapılır (ör. alıcıyı satıcı yapmak).
  # Controller seviyesinde parametre ve yetki kontrolü, model seviyesinde User#role doğrulaması çalışır.
  def update
    role = role_params[:role].to_s
    return user_error("Rol seçilmelidir", :unprocessable_entity) if role.blank?
    return user_error("Geçersiz rol: #{role}", :unprocessable_entity) if User::ROLES.exclude?(role)
    return user_error("Kendi rolünüzü değiştiremezsiniz", :unprocessable_entity) if @user.id == current_user.id

    if @user.update(role: role)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@user, partial: "admin/users/user", locals: { user: @user }),
            turbo_stream.append("notifications", partial: "shared/notice", locals: { message: "#{@user.name} artık #{helpers.role_label(@user.role)}.", error: false })
          ]
        end
        format.html { redirect_to admin_users_path, notice: "Rol güncellendi.", status: :see_other }
      end
    else
      message = @user.errors.full_messages.to_sentence
      @user.restore_attributes
      user_error(message, :unprocessable_entity, replace_row: true)
    end
  end

  def destroy
    return user_error("Kendi hesabınızı bu uç noktadan silemezsiniz", :unprocessable_entity) if @user.id == current_user.id

    @user.destroy!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@user) }
      format.html { redirect_to admin_users_path, notice: "Kullanıcı silindi.", status: :see_other }
    end
  end

  private

  def authenticate_admin!
    require_role!("admin", message: "Bu işlem için admin yetkisi gerekiyor")
  end

  def find_user
    @user = User.find(user_route_params[:id])
  end

  # replace_row: başarısız rol değişikliğinde satırdaki seçim kutusu eski role döndürülür.
  def user_error(message, status, replace_row: false)
    respond_to do |format|
      format.turbo_stream do
        streams = [ turbo_stream.append("notifications", partial: "shared/notice", locals: { message: message, error: true }) ]
        streams << turbo_stream.replace(@user, partial: "admin/users/user", locals: { user: @user }) if replace_row
        render turbo_stream: streams, status: status
      end
      format.html { redirect_to admin_users_path, alert: message }
    end
  end

  def render_new_user_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("admin_new_user_form", partial: "admin/users/form", locals: { user: @new_user }),
               status: :unprocessable_entity
      end
      format.html do
        @users = User.order(:id)
        render :index, status: :unprocessable_entity
      end
    end
  end

  def new_user_params
    permitted_params(user: [ :name, :email, :password, :role ])[:user] || ActionController::Parameters.new
  end

  def user_route_params
    permitted_params([ :id ])
  end

  def role_params
    permitted_params(user: [ :role ])[:user] || ActionController::Parameters.new
  end
end
