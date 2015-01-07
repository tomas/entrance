Entrance.configure do |config|
  config.remember_for              = 1.month
  config.access_denied_redirect_to = '/login'
  config.cookie_secure             = Rails.env.production?
end
