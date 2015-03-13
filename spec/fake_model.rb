require 'entrance'

Entrance.configure do |config|


  config.access_denied_redirect_to = '/login'
end

############################################################
# admin user model

class FakeUser
  include Entrance::Model
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

  provides_entrance do |fields|
    fields.unique_key  = 'email'
    fields.username    = 'email'
    fields.password    = 'password'

    # disabling reset password and remember options
    fields.reset_token    = nil
    fields.remember_token = nil
  end

end
