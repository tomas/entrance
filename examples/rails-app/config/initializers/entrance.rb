puts 'Initializing Entrance...'

Entrance.configure do |config|
  config.remember_for              = 1.month
  config.cipher                    = Entrance::Ciphers::SHA1
  config.secret                    = 'somethingveryveryveryveryverysecret'
  config.access_denied_redirect_to = '/login'
  config.cookie_secure             = Rails.env.production?
end
