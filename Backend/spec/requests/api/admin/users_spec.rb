require "rails_helper"

RSpec.describe "Api::Admin::Users", type: :request do
  it "allows admins to list and delete other users" do
    admin = User.create!(name: "Admin", email: "admin@example.com", password: "secret123", role: "admin")
    target = User.create!(name: "User", email: "user@example.com", password: "secret123")
    session = admin.issue_session!
    cookies[:session_token] = session.fetch(:session_token)

    get "/api/admin/users"
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.map { |user| user["id"] }).to include(target.id)

    delete "/api/admin/users/#{target.id}"
    expect(response).to have_http_status(:no_content)
    expect(User.exists?(target.id)).to be(false)
  end

  it "forbids regular users from deleting users" do
    user = User.create!(name: "User", email: "user@example.com", password: "secret123")
    target = User.create!(name: "Target", email: "target@example.com", password: "secret123")
    session = user.issue_session!
    cookies[:session_token] = session.fetch(:session_token)

    delete "/api/admin/users/#{target.id}"

    expect(response).to have_http_status(:forbidden)
    expect(User.exists?(target.id)).to be(true)
  end
end
