module Entrance

  class Config

    attr_accessor *%w(
      model cipher secret stretches
      unique_key username_attr password_attr salt_attr
      remember_token_attr remember_until_attr reset_token_attr reset_until_attr
      access_denied_redirect_to access_denied_message_key
      reset_password_mailer reset_password_method reset_password_window remember_for
      cookie_domain cookie_secure cookie_path cookie_httponly
    )

    def initialize
      @model                      = 'User'
      @cipher                     = Entrance::Ciphers::BCrypt # or Entrance::Ciphers::SHA1 
      @secret                     = nil
      @stretches                  = 10
      @salt_attr                  = nil
      @unique_key                 = 'id'
      @username_attr              = 'email'
      @password_attr              = 'password_hash'
      @remember_token_attr        = 'remember_token'
      @remember_until_attr        = 'remember_token_expires_at'
      @reset_token_attr           = 'reset_token'
      @reset_until_attr           = 'reset_token_expires_at'
      @access_denied_redirect_to  = '/'
      @access_denied_message_key  = nil # e.g. 'messages.access_denied'
      @reset_password_mailer      = 'UserMailer'
      @reset_password_method      = 'reset_password_request'
      @reset_password_window      = 60 * 60 # 1.hour
      @remember_for               = 60 * 24 * 14 # 2.weeks
      @cookie_domain              = nil
      @cookie_secure              = true
      @cookie_path                = '/'
      @cookie_httponly            = false
    end

    def validate!
      if cipher == Ciphers::SHA1 && secret.nil?
        raise "The SHA1 cipher requires a valid config.secret to be set."
      end
    end

    def can?(what, val = nil)
      if val
        instance_variable_set("@can_#{what}", val)
      else
        !!instance_variable_get("@can_#{what}")
      end
    end

    def permit!(option)
      raise "#{option} is disabled!" unless can?(option)
    end

  end

end