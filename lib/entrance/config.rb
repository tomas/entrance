module Entrance

  class Config

    attr_accessor *%w(
      model local_auth remote_auth cipher secret stretches
      access_denied_redirect_to access_denied_message_key
      reset_password_mailer reset_password_method reset_password_window remember_for
      cookie_domain cookie_secure cookie_path cookie_httponly
    )

    def initialize
      @model                      = 'User'
      @local_auth                 = true
      @remote_auth                = false

      # strategies
      @cipher                     = Entrance::Ciphers::BCrypt # or Entrance::Ciphers::SHA1
      @secret                     = nil
      @stretches                  = 10

      # access denied
      @access_denied_redirect_to  = '/login'
      @access_denied_message_key  = nil # e.g. 'messages.access_denied'

      # reset password
      @reset_password_mailer      = 'UserMailer'
      @reset_password_method      = 'reset_password_request'
      @reset_password_window      = 60 * 60 # 1.hour

      # remember me & cookies
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
