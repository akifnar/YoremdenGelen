require "rails_helper"

# Kayan oturum süresi: bellekteki kullanıcıyla; yalnızca UPDATE'in yapılıp yapılmadığı kontrol edilir.
RSpec.describe User, "oturum süresi", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { persisted_user(role: "buyer") }

  it "extends the session to 12 hours from now once less than half of the idle timeout is left" do
    freeze_time do
      user.session_token_expires_at = 5.hours.from_now
      expect(user).to receive(:update_column).with(:session_token_expires_at, 12.hours.from_now)

      user.touch_session!
    end
  end

  it "does not write while the session is still fresh" do
    user.session_token_expires_at = 11.hours.from_now
    expect(user).not_to receive(:update_column)

    user.touch_session!
  end
end
