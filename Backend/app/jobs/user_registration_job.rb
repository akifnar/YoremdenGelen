class UserRegistrationJob < ApplicationJob
  queue_as :default

  def perform(name:, email:, password_digest:)
    user = User.create!(name: name, email: email, password_digest: password_digest, role: "buyer")
    user.issue_email_verification!
    VerificationMailerJob.perform_later(user.id)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
    Rails.logger.warn("UserRegistrationJob skipped #{email}: #{error.message}")
  end
end
