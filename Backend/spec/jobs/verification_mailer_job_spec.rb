require "rails_helper"

RSpec.describe VerificationMailerJob, type: :job do
  it "delivers verification mail for a pending, unexpired user" do
    user = User.create!(name: "Test", email: "test@example.com", password: "secret123")
    user.issue_email_verification!

    expect { described_class.perform_now(user.id) }.to change(ActionMailer::Base.deliveries, :count).by(1)
  end

  it "does not send mail after the verification token expires" do
    user = User.create!(name: "Test", email: "test@example.com", password: "secret123")
    user.issue_email_verification!
    user.update!(email_verification_expires_at: 1.minute.ago)

    expect { described_class.perform_now(user.id) }.not_to change(ActionMailer::Base.deliveries, :count)
  end
end
