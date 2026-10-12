require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  it "sends an email with a verification link that carries the token" do
    user = User.create!(name: "Test", email: "test@example.com", password: "secret123")
    user.issue_email_verification!

    mail = described_class.verification_email(user)

    expect(mail.to).to eq([ user.email ])
    expect(mail.subject).to eq("E-posta adresinizi doğrulayın")
    decoded_parts = mail.parts.map(&:decoded).join(" ")
    expect(decoded_parts).to include(user.email_verification_token)
    expect(decoded_parts).to include("10 dakika")
  end
end
