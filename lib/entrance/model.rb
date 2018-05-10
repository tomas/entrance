module Entrance
  module Model

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def provides_entrance(options = {}, &block)
        local  = options.delete(:local) != false # true by default
        remote = options.delete(:remote) == true # false by default
        skip_checks = options.delete(:skip_checks)

        if local === false && remote === false
          raise "You have to enable either local or remote auth via `provides_entrance`."
        end

        Entrance.config.model       = self.name
        Entrance.config.local_auth  = local
        Entrance.config.remote_auth = remote

        # if the target model class does not have a Model.where() method,
        # then login_by_session wont work, nor the ClassMethods below.
        # won't work so we cannot continue.
        unless self.respond_to?(:where)
          raise "#{self.name} does not have a .where() finder class method. Cannot continue."
        end

        fields = Entrance.fields
        yield fields if block_given?

        # username and remember token are used both for local and remote (omniauth)
        fields.validate(:username) unless skip_checks
        include Entrance::Model::RememberMethods if fields.validate_option(:remember)

        if local # allows password & reset
          fields.validate(:password) unless skip_checks
          include Entrance::Model::ResetMethods if fields.validate_option(:reset)

          if self.respond_to?(:validates)
            validates :password, :presence => true, :length => 6..32, :if => :password_required?
            validates :password, :confirmation => true, :if => :password_required?
            validates :password_confirmation, :presence => true, :if => :password_required?
          end
        end

        if remote
          fields.validate(:auth_provider, :auth_uid) unless skip_checks
          include RemoteAuthMethods if local # no need to if only remote
        end
      end

      def authenticate(username, password)
        raise 'Local auth disabled!' unless Entrance.config.local_auth
        return if [username, password].any? { |v| v.nil? || v.strip == '' }

        query = {}
        query[Entrance.fields.username] = username.to_s.downcase.strip
        if u = where(query).first
          return u.authenticated?(password) ? u : nil
        end
      end

      def with_password_reset_token(token)
        Entrance.config.permit!(:reset)
        return if token.nil?

        query = {}
        query[Entrance.fields.reset_token] = token.to_s.strip
        if u = where(query).first \
          and (!Entrance.fields.reset_until || u.send(Entrance.fields.reset_until) > Time.now)
            return u
        end
      end

    end

    module ResetMethods

      def request_password_reset!
        send(Entrance.fields.reset_token + '=', Entrance.generate_token)
        if Entrance.fields.reset_until
          timestamp = Time.now + Entrance.config.reset_password_window
          update_attribute(Entrance.fields.reset_until, timestamp)
        end
        if save(:validate => false)
          method = Entrance.config.reset_password_method
          Entrance.config.reset_password_mailer.constantize.send(method, self).deliver
        end
      end

    end

    module RememberMethods

      def remember_me!(until_date = nil)
        token = Entrance.generate_token
        update_attribute(Entrance.fields.remember_token, token) or return
        update_remember_token_expiration!(until_date) if Entrance.fields.remember_until
        token
      end

      def forget_me!
        update_attribute(Entrance.fields.remember_token, nil)
        update_attribute(Entrance.fields.remember_until, nil) if Entrance.fields.remember_until
      end

      private

      def update_remember_token_expiration!(until_date = nil)
        timestamp = Time.now + (until_date || Entrance.config.remember_for).to_i
        update_attribute(Entrance.fields.remember_until, timestamp)
      end

    end

    module RemoteAuthMethods

      def from_remote_auth?
        send(::Entrance.fields.auth_provider).present? \
          && send(::Entrance.fields.auth_uid).present?
      end

      private

      def password_required?
        !from_remote_auth? && super
      end

    end

    def authenticated?(string)
      Entrance.config.cipher.match?(read_password, string, get_salt)
    end

    def password
      @password || read_password
    end

    def password=(new_password)
      return if new_password.nil?

      @password = new_password # for validation
      @password_changed = true

      # if we're using salt and it is empty, generate one
      if Entrance.fields.salt \
        and send(Entrance.fields.salt).nil?
          self.send(Entrance.fields.salt + '=', Entrance.generate_token)
      end

      self.send(Entrance.fields.password + '=', encrypt_password(new_password))
    end

    private

    def read_password
      send(Entrance.fields.password)
    end

    def encrypt_password(string)
      Entrance.config.cipher.encrypt(string, get_salt)
    end

    def get_salt
      Entrance.fields.salt && send(Entrance.fields.salt)
    end

    def password_required?
      password.nil? || @password_changed
    end

  end
end
