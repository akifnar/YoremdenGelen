require "rails_helper"

RSpec.describe "Admin kullanıcı yönetimi", type: :request do
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:target) { persisted_user(id: 72, role: "buyer") }

  before { allow(User).to receive(:find).with(target.id.to_s).and_return(target) }

  it "lists users and lets admins delete other users" do
    admin = sign_in_stubbed(persisted_user(id: 71, role: "admin"))
    allow(User).to receive(:order).and_return(relation_double([ admin, target ]))
    expect(target).to receive(:destroy!)

    get admin_users_path
    expect(response.body).to include("Kullanıcı yönetimi", target.email)

    delete admin_user_path(target), headers: turbo_stream

    expect(response.body).to include(%(action="remove"), %(target="user_#{target.id}"))
  end

  it "forbids non-admins from deleting users" do
    sign_in_stubbed(persisted_user(id: 73, role: "buyer"))
    expect(target).not_to receive(:destroy!)

    delete admin_user_path(target), headers: turbo_stream

    expect(response).to have_http_status(:forbidden)
  end
end
