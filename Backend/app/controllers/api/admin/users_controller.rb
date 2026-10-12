class Api::Admin::UsersController < ApplicationController
  before_action :authenticate_admin!

  def index
    users = User.order(:id).select(:id, :name, :email, :role, :created_at)
    render json: users
  end

  def destroy
    user = User.find(user_route_params[:id])
    return render json: { errors: [ "Kendi hesabınızı bu uç noktadan silemezsiniz" ] }, status: :unprocessable_entity if user.id == @current_user.id

    user.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Kullanıcı bulunamadı" ] }, status: :not_found
  end

  private

  def authenticate_admin!
    return if current_user.role == "admin"

    render json: { errors: [ "Bu işlem için admin yetkisi gerekiyor" ] }, status: :forbidden
  end

  def user_route_params
    permitted_params([ :id ])
  end
end
