module Entrance
  module Model

    def self.included(base)

      # if the target model class does not have a Model.where() method,
      # then login_by_session wont work, nor the ClassMethods below.
      # won't work so we cannot continue.
      unless base.respond_to?(:where)
        raise "#{base.name} does not have a .where() finder class method. Cannot continue."
      end

      base.extend(ClassMethods)
    end

    module ClassMethods

      def validate_entrance!
        fields = if self.respond_to?(:columns)   # ActiveRecord::Base
          columns.collect(&:name)
        elsif self.respond_to?(:keys)            # MongoMapper::Document
          keys.keys
        else                                     # just get setters in the class
          instance_methods(false).select { |m| m[/\=$/] }.map { |s| s.to_s.sub('=', '') }
        end.map { |el| el.to_sym }

        %w(username_attr password_attr).each do |key|
          field = Entrance.config.send(key)
          unless fields.include?(field.to_sym)
            raise "Couldn't find '#{field}' in #{base.name} model."
          end
        end

        %w(remember reset).each do |what|
          if field = Entrance.config.send("#{what}_token_attr")
            until_field = Entrance.config.send("#{what}_until_attr")

            unless fields.include?(field.to_sym)
              raise "No #{Entrance.config.send("#{what}_token_attr")} field found. \
                     Set the config.#{what}_token_attr option to nil to disable the #{what} option."
            end

            if until_field
              unless fields.include?(until_field.to_sym)
                raise "Couldn't find a #{Entrance.config.send("#{what}_until_attr")} field. Cannot continue."
              end
            else
              puts "Disabling expiration timestamp for the #{what} option. This is a VERY bad idea."
            end

            Entrance.config.can?(what, true)
            self.send(:include, what.to_sym == :remember ? RememberMethods : ResetMethods)
          end
        end

        if self.respond_to?(:validates)
          validates :password, :presence => true, :length => 6..32, :if => :password_required?
          validates :password, :confirmation => true, :if => :password_required?
          validates :password_confirmation, :presence => true, :if => :password_required?
        end
      end

      def authenticate(username, password)
        return if [username, password].any? { |v| v.nil? || v.strip == '' }

        query = {}
        query[Entrance.config.username_attr] = username.to_s.downcase.strip
        if u = where(query).first
          return u.authenticated?(password) ? u : nil
        end
      end

      def with_password_reset_token(token)
        Entrance.config.permit!(:reset)
        return if token.nil?

        query = {}
        query[Entrance.config.reset_token_attr] = token.to_s.strip
        if u = where(query).first \
          and (!Doorman.config.reset_until_attr || u.send(Doorman.config.reset_until_attr) > Time.now)
            return u
        end
      end

    end

    module ResetMethods

      def request_password_reset!
        send(Entrance.config.reset_token_attr + '=', Entrance.generate_token)
        if Doorman.config.reset_until_attr
          timestamp = Time.now + Entrance.config.reset_password_window
          update_attribute(Entrance.config.reset_until_attr, timestamp)
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
        update_attribute(Entrance.config.remember_token_attr, token) or return
        update_remember_token_expiration!(until_date) if Entrance.config.remember_until_attr
        token
      end

      def update_remember_token_expiration!(until_date = nil)
        timestamp = Time.now + (until_date || Entrance.config.remember_for).to_i
        update_attribute(Entrance.config.remember_until_attr, timestamp)
      end

      def forget_me!
        update_attribute(Entrance.config.remember_token_attr, nil)
        update_attribute(Entrance.config.remember_until_attr, nil) if Entrance.config.remember_until_attr
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
      if Entrance.config.salt_attr \
        and send(Entrance.config.salt_attr).nil?
          self.send(Entrance.config.salt_attr + '=', Entrance.generate_token)
      end

      self.send(Entrance.config.password_attr + '=', encrypt_password(new_password))
    end

    private

    def read_password
      send(Entrance.config.password_attr)
    end

    def encrypt_password(string)
      Entrance.config.cipher.encrypt(string, get_salt)
    end

    def get_salt
      Entrance.config.salt_attr && send(Entrance.config.salt_attr)
    end

    def password_required?
      password.nil? || @password_changed
    end

  end
end
