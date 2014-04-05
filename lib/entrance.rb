####################################
# Entrance
#
# By Tomas Pollak
# Simple Ruby Authentication Library
###################################

=begin

In your controller:
  include Entrance::Controller

  - Provides authenticate_and_login, login!(user), logout! methods
  - Provices login_required, logged_in? and logged_out? helpers

In your model:

  include Entrance::Model

  - Provides Model.authenticate(username, password)
  - Provices Model#remember_me! and Model#forget_me!
  - Provides Model#password getter and setter
  - Provides Model#request_password_reset!
=end

require 'entrance/controller'
require 'entrance/model'
require 'entrance/ciphers'

module Entrance

  REMEMBER_ME_TOKEN = 'auth_token'

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end

  def self.generate_token(length = 40)
    SecureRandom.hex(length/2).encode('UTF-8')
  end

  class Config

    attr_accessor *%w(
      model mailer_class cipher secret stretches
      username_attr password_attr salt_attr
      remember_token_attr remember_until_attr reset_token_attr reset_until_attr
      access_denied_redirect_to access_denied_message_key reset_password_window remember_for
      cookie_domain cookie_secure cookie_path cookie_httponly
    )

    def initialize
      @model                 = 'User'
      @mailer_class          = 'UserMailer'
      @cipher                = Ciphers::SHA1
      @secret                = nil
      @stretches             = 1
      @username_attr         = 'email'
      @password_attr         = 'password_hash'
      @salt_attr             = nil
      @remember_token_attr   = 'remember_token'
      @remember_until_attr   = 'remember_token_expires_at'
      @reset_token_attr      = 'reset_token'
      @reset_until_attr      = 'reset_token_expires_at'
      @access_denied_redirect_to  = '/'
      @access_denied_message_key = 'messages.access_denied'
      @reset_password_window = 1.hour
      @remember_for          = 2.weeks
      @cookie_domain         = nil
      @cookie_secure         = true
      @cookie_path           = '/'
      @cookie_httponly       = false
    end

  end

end
