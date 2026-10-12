require "rails_helper"

RSpec.describe "Api::Auth", type: :request do
  it "registers a user and enqueues email verification" do
    expect do
      post "/api/auth/register", params: { user: { name: "Test", email: "test@example.com", password: "secret123", role: "admin", unexpected: "ignored" } }, as: :json
    end.to have_enqueued_job(VerificationMailerJob)

    expect(response).to have_http_status(:created)
    expect(User.last.role).to eq("user")
    expect(User.last.email_verified_at).to be_nil
    expect(User.last.session_token).to eq(User.token_digest(response.cookies.fetch("session_token")))
    expect(response.parsed_body.dig("user", "id")).to eq(User.last.id)
  end

  it "stores a hashed remember cookie when registration requests a remembered session" do
    post "/api/auth/register",
         params: { user: { name: "Remembered", email: "remembered@example.com", password: "secret123", remember_me: true } },
         as: :json

    user = User.find_by!(email: "remembered@example.com")
    expect(response).to have_http_status(:created)
    expect(user.remember_token).to eq(response.cookies.fetch("remember_token"))
    expect(response.headers["Set-Cookie"].join(" ").downcase).to include("remember_token=", "expires=")
  end

  it "does not allow login before verification and succeeds after verification" do
    user = User.create!(name: "Test", email: "test@example.com", password: "secret123")
    post "/api/auth/login", params: { user: { email: user.email, password: "secret123" } }, as: :json
    expect(response).to have_http_status(:forbidden)

    user.update!(email_verified_at: Time.current)
    post "/api/auth/login", params: { user: { email: user.email, password: "secret123" } }, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.dig("user", "id")).to eq(user.id)
    expect(response.parsed_body).not_to include("session_token", "remember_token")
    raw_session_token = response.cookies.fetch("session_token")
    expect(user.reload.session_token).to eq(User.token_digest(raw_session_token))
    session_cookie_header = response.headers["Set-Cookie"].to_s.lines.find { |line| line.start_with?("session_token=") }
    expect(session_cookie_header).to include("httponly")
    expect(session_cookie_header.downcase).not_to include("expires", "max-age")
  end

  it "rejects registration when the request already has an authenticated session" do
    user = User.create!(name: "Signed in", email: "signed-in@example.com", password: "secret123", email_verified_at: Time.current)
    post "/api/auth/login", params: { user: { email: user.email, password: "secret123" } }, as: :json
    expect(response).to have_http_status(:success)

    expect do
      post "/api/auth/register", params: { user: { name: "Another", email: "another@example.com", password: "secret123" } }, as: :json
    end.not_to change(User, :count)
    expect(response).to have_http_status(:forbidden)
  end

  it "issues and rotates a remember token when requested" do
    user = User.create!(name: "Test", email: "remember@example.com", password: "secret123", email_verified_at: Time.current)
    post "/api/auth/login", params: { user: { email: user.email, password: "secret123", remember_me: true } }, as: :json

    expect(response).to have_http_status(:success)
    remember_cookie = response.cookies.fetch("remember_token")
    expect(user.reload.remember_token).to eq(remember_cookie)
    expect(response.headers["Set-Cookie"].join(" ")).to include("remember_token=")
    expect(response.headers["Set-Cookie"].join(" ").downcase).to include("expires=")

    user.update!(session_token_expires_at: 1.minute.ago)
    post "/api/auth/refresh", as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.dig("user", "id")).to eq(user.id)
    refreshed_cookie = response.cookies.fetch("remember_token")
    expect(refreshed_cookie).not_to eq(remember_cookie)
    expect(user.reload.remember_token).to eq(refreshed_cookie)
  end

  it "verifies a valid email token and rejects an expired one" do
    user = User.create!(name: "Test", email: "test@example.com", password: "secret123")
    user.issue_email_verification!
    post "/api/auth/verify-email", params: { token: user.email_verification_token }, as: :json
    expect(response).to have_http_status(:success)
    expect(user.reload.email_verified_at).to be_present
  end
end
