class UserMailer < ApplicationMailer
  def verification_email(user)
    @user = user
    @verification_url = verify_email_url(token: user.email_verification_token)
    mail(to: @user.email, subject: "E-posta adresinizi doğrulayın")
  end
end
