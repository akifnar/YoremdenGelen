require "rails_helper"

# DB zorunlu: kayıt job'ı, şifre doğrulaması ve oturum/remember token özetlerinin kullanıcıya yazılması test ediliyor.
RSpec.describe "Kimlik doğrulama", type: :request do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { User.create!(name: "Ayşe", email: "ayse@example.com", password: "secret123", email_verified_at: Time.current) }

  def log_in(remember_me: false)
    post login_path, params: { user: { email: user.email, password: "secret123", remember_me: remember_me ? "1" : "0" } }
  end

  it "accepts registration and creates a buyer in a background job without logging in" do
    expect do
      post register_path, params: { user: { name: "Test", email: "test@example.com", password: "secret123", role: "admin" } }
    end.to have_enqueued_job(UserRegistrationJob)

    expect(response).to redirect_to(login_path)
    expect(response.cookies["session_token"]).to be_nil
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.to_s).not_to include("secret123")

    expect { perform_enqueued_jobs(only: UserRegistrationJob) }.to change(User, :count).by(1).and have_enqueued_job(VerificationMailerJob)
    expect(User.last).to have_attributes(role: "buyer", email_verified_at: nil)
  end

  it "rejects invalid registration synchronously without enqueuing a job" do
    user

    expect do
      post register_path, params: { user: { name: "Test", email: "AYSE@example.com", password: "secret123" } }
    end.not_to have_enqueued_job(UserRegistrationJob)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not allow login before verification" do
    user.update!(email_verified_at: nil)
    log_in
    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include("E-posta adresinizi doğrulayın")
  end

  it "stores only the digest of the encrypted session cookie" do
    log_in

    expect(response).to redirect_to(root_path)
    raw_session_token = encrypted_cookie(:session_token)
    expect(response.cookies.fetch("session_token")).not_to include(raw_session_token)
    expect(user.reload.session_token).to eq(User.token_digest(raw_session_token))
    session_cookie_header = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_token=") }
    expect(session_cookie_header).to include("httponly")
    expect(session_cookie_header.downcase).not_to include("expires", "max-age")
  end

  it "keeps a non-remembered login only in a browser-session cookie, without a remember token" do
    log_in

    set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
    expect(set_cookie).to match(/^session_token=/)
    expect(set_cookie).not_to match(/^remember_token=[^;]/)
    expect(set_cookie.lines.grep(/^session_token=/).first.downcase).not_to include("expires", "max-age")
    expect(user.reload.remember_token).to be_nil
  end

  it "keeps the session alive while it is used and ends it after 12 idle hours" do
    log_in

    travel 7.hours do
      get cart_path
      expect(response).to have_http_status(:ok)
      expect(user.reload.session_token_expires_at).to be_within(1.minute).of(12.hours.from_now)
    end

    travel 20.hours do # son kullanımdan 13 saat sonra
      get cart_path
      expect(response).to redirect_to(login_path(returnTo: "/sepet"))
    end
  end

  it "rejects registration when the request already has an authenticated session" do
    log_in

    expect do
      post register_path, params: { user: { name: "Another", email: "another@example.com", password: "secret123" } }
    end.not_to have_enqueued_job(UserRegistrationJob)
    expect(response).to redirect_to(root_path)
  end

  it "restores an expired session from the remember cookie and rotates it" do
    log_in(remember_me: true)
    remember_cookie = encrypted_cookie(:remember_token)
    expect(user.reload.remember_token).to eq(User.token_digest(remember_cookie))

    user.update!(session_token_expires_at: 1.minute.ago)
    get cart_path

    expect(response).to have_http_status(:ok)
    refreshed_cookie = encrypted_cookie(:remember_token)
    expect(refreshed_cookie).not_to eq(remember_cookie)
    expect(user.reload.remember_token).to eq(User.token_digest(refreshed_cookie))
  end

  it "verifies a valid email token" do
    user.update!(email_verified_at: nil)
    user.issue_email_verification!

    post verify_email_path, params: { token: user.email_verification_token }

    expect(response).to have_http_status(:ok)
    expect(user.reload.email_verified_at).to be_present
  end
end
