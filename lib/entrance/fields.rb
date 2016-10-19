module Entrance

  class Fields

    attr_accessor *%w(
      unique_key salt username password
      remember_token remember_until reset_token reset_until
      name auth_provider auth_uid
    )

    def initialize
      @unique_key            = 'id'
      @salt                  = nil
      @username              = 'email'
      @password              = 'password_hash'

      # remember and reset
      @remember_token        = 'remember_token' # set to nil to disable 'remember me' option
      @remember_until        = 'remember_token_expires_at'
      @reset_token           = 'reset_token'    # set to nil to disable 'reset password' option
      @reset_until           = 'reset_token_expires_at'

      # omniauth
      @name                  = 'name'
      @auth_provider         = 'auth_provider'
      @auth_uid              = 'auth_uid'
    end

    def validate(*attrs)
      attrs.each do |attr|
        field = send(attr)
        unless fields.include?(field.to_sym)
          raise "Couldn't find '#{field}' in the #{Entrance.model.name} model."
        end
      end
    end

    def validate_option(what)
      if field = send("#{what}_token")
        until_field = send("#{what}_until")

        unless fields.include?(field.to_sym)
          raise "No #{field} field found. \
                 Set the fields.#{what}_token option to nil to disable the #{what} option."
        end

        if until_field
          unless fields.include?(until_field.to_sym)
            raise "Couldn't find a #{until_field} field. Cannot continue."
          end
        else
          puts "Disabling expiration timestamp for the #{what} option. This is a VERY bad idea."
        end

        Entrance.config.can?(what, true)
      end
    end

    protected

    def fields
      @fields ||= get_model_fields
    end

    def get_model_fields
      model = Entrance.model
       if model.respond_to?(:columns)          # ActiveRecord::Base
        model.columns.collect(&:name)
      elsif model.respond_to?(:keys)           # MongoMapper::Document
        model.keys.keys
      else                                     # just get setters in the class
        model.instance_methods(false).select { |m| m[/\=$/] }.map { |s| s.to_s.sub('=', '') }
      end.map { |el| el.to_sym }
    end

  end

end
