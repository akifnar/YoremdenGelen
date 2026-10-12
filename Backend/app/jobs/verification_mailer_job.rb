class VerificationMailerJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user && user.email_verification_expires_at&.future?

    UserMailer.verification_email(user).deliver_now
  end
end
