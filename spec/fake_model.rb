require 'entrance'

Entrance.configure do |config|
  config.model         = 'FakeUser'
  config.unique_key    = 'email'
  config.username_attr = 'email'
  config.password_attr = 'password'

  # disabling reset password and remember options
  config.reset_token_attr    = nil
  config.remember_token_attr = nil
  # config.cookie_secure       = false

  config.access_denied_redirect_to = '/login'
end

############################################################
# admin user model

class FakeUser
  attr_accessor :email, :password #, :remember_token

  USERS = {
    'test@test.com' => 'test',
    'foo@test.com'  => 'foo'
  }

  def self.where(query)
    email = query['email']
    # puts "User logging in: #{email}"
    return [] unless USERS[email]

    user = new
    user.email    = email
    user.password = USERS[email]

    # puts "Initialized user: #{user.inspect}"
    [user]
  end

  def update_attribute(key, val)
    # puts "Updating #{key} -> #{val}"
    send("#{key}=", val)
  end

  def authenticated?(string)
    password == string
  end

  include Entrance::Model # ensure after we declare the .where method

end
