# Uygulama auth/sepet cookie'lerini cookies.encrypted ile yazar; request spec'lerinde aynı anahtarla
# şifreleyip çözmek için kullanılır.
module EncryptedCookies
  def set_encrypted_cookie(name, value)
    jar = ActionDispatch::TestRequest.create(Rails.application.env_config.dup).cookie_jar
    jar.encrypted[name] = value
    cookies[name] = jar[name]
  end

  def encrypted_cookie(name)
    request = ActionDispatch::TestRequest.create(Rails.application.env_config.dup)
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).encrypted[name]
  end
end

RSpec.configure do |config|
  config.include EncryptedCookies, type: :request
end
