module Entrance

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