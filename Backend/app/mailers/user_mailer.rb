class UserMailer < ApplicationMailer
  def verification_email(user)
    @user = user
    @verification_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/verify-email?token=#{ERB::Util.url_encode(user.email_verification_token)}"
    mail(to: @user.email, subject: "E-posta adresinizi doğrulayın")
  end
end
