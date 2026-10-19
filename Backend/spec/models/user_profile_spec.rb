require "rails_helper"

# Profil alanları bellekteki kayıtlarla doğrulanır; Active Storage eki save edilmediği için dosya/DB yazılmaz.
RSpec.describe User, "profil alanları", type: :model do
  def attach_avatar(user, content_type:, bytes: 10)
    # attach kalıcı kayıtta hemen yazar; atama ise eki save'e kadar bellekte bekletir.
    user.avatar = { io: StringIO.new("x" * bytes), filename: "avatar", content_type: content_type, identify: false }
    user
  end

  let(:user) { persisted_user(role: "buyer") }

  it "accepts small PNG, JPEG and WebP avatars" do
    User::AVATAR_CONTENT_TYPES.each do |content_type|
      expect(attach_avatar(persisted_user, content_type: content_type)).to be_valid, content_type
    end
  end

  it "rejects other file types and files over 2 MB" do
    expect(attach_avatar(user, content_type: "application/pdf")).not_to be_valid
    expect(user.errors[:avatar]).to include("PNG, JPEG veya WebP olmalıdır")

    big = attach_avatar(persisted_user(id: 2), content_type: "image/png", bytes: User::AVATAR_MAX_SIZE + 1)
    expect(big).not_to be_valid
    expect(big.errors[:avatar]).to include("en fazla 2 MB olabilir")
  end

  it "rejects passwords longer than bcrypt can hash" do
    user.password = "a" * 73
    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end
end
