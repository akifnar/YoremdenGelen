class EmailVerificationsController < ApplicationController
  skip_before_action :authenticate_request!

  # E-postadaki bağlantı (GET) durumu değiştirmez; sayfadaki form Stimulus ile
  # kendiliğinden POST edilir ve sonuç Turbo Stream ile aynı sayfada gösterilir.
  def show
    @token = verification_params[:token]
  end

  def create
    user = User.find_by(email_verification_token: verification_params[:token]) if verification_params[:token].present?
    verified = user&.verify_email!(verification_params[:token])
    @message = verified ? "E-posta adresi doğrulandı" : "Doğrulama bağlantısı geçersiz veya süresi dolmuş"
    @success = verified.present?
    status = verified ? :ok : :unprocessable_entity

    respond_to do |format|
      format.turbo_stream { render status: status }
      format.html { render :show, status: status }
    end
  end

  private

  def verification_params
    permitted_params([ :token ])
  end
end
