require "rails_helper"

RSpec.describe UserRegistrationJob, type: :job do
  let(:password_digest) { User.new(password: "secret123").password_digest }

  it "creates the user, issues a verification token and enqueues the verification mail" do
    expect do
      described_class.perform_now(name: "Test", email: "test@example.com", password_digest: password_digest)
    end.to change(User, :count).by(1).and have_enqueued_job(VerificationMailerJob)

    user = User.last
    expect(user.email_verification_token).to be_present
    expect(user.authenticate("secret123")).to eq(user)
  end

  it "skips an email that was registered after the request was accepted" do
    User.create!(name: "Existing", email: "test@example.com", password: "secret123")

    expect do
      described_class.perform_now(name: "Test", email: "test@example.com", password_digest: password_digest)
    end.not_to change(User, :count)
  end
end
