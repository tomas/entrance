require 'entrance'
require 'omniauth'

=begin

require 'sinatra/base'
require 'omniauth-twitter'
require 'entrance/omniauth'

class Hello < Sinatra::Base
  register Entrance::OmniAuth

  set :auth_test, false # only true for testing
  set :auth_providers {
    :twitter => {
      :key => 'foobar'
    }
  }
end

=end

module Entrance

  module OmniAuth

    class << self

      def registered(app)

        ::Entrance.model.class_eval do

          def via_omniauth?
            send(::Entrance.config.auth_provider_attr).present? \
              && send(::Entrance.config.auth_uid_attr).present?
          end

          def password_required?
            !via_omniauth? && (password.nil? || @password_changed)
          end

        end

        app.send(:include, Entrance::Controller) # provides redirects, etc

        app.use ::OmniAuth::Builder do
          # this is run after the app has initialized, so it's safe to use it here.
          if app.settings.respond_to?(:auth_test)
            ::OmniAuth.config.test_mode = true if app.settings.auth_test?
          end

          app.settings.auth_providers.each do |name, options|
            # puts "Initializing #{name} provider: #{options.inspect}"
            # omniauth expects provider(:name, arg1, arg2, arg3), so we need to map only the values
            opts = options && options.any? ? options.values : []
            provider(name, *opts)
          end
        end

        # make _method=delete work in POST requests:
        app.enable :method_override

        [:get, :post].each do |action|

          app.send(action, '/auth/:provider/callback') do
            auth = request.env['omniauth.auth']
            user = ::Entrance::OmniAuth.auth_or_create(auth) or return return_401

            if ::Entrance::OmniAuth.valid_user?(user)
              login!(user)
              flash[:success] = 'Welcome back!' if respond_to?(:flash)
              redirect_to_stored_or(to('/'))
            else
              redirect_with('/', :error, 'Unable to authenticate. Please try again.')
            end
          end

        end # get, post

        app.get '/auth/failure' do
          redirect_with('/', :error, params[:message])
        end

      end # registered

      def logger
        @logger ||= Logger.new('./log/omniauth.log')
      end

      def log(str)
        logger.info(str)
      end

      def valid_user?(user)
        if user.respond_to?(:active?) and !user.active?
          return false
        end
        user.valid?
      end

      def can_authenticate_with?(service)
        return true if ::OmniAuth.config.test_mode and service.to_sym == :default
        settings.auth_providers.keys.map(&:to_sym).include?(service.to_sym)
      end

      def find_user_with_username(username)
        query = {}
        query[::Entrance.config.username_attr] = username # .to_s.downcase.strip
        ::Entrance.model.where(query).first
      end

      def find_user_with_provider_and_uid(provider, uid)
        query = {}
        query[::Entrance.config.auth_provider_attr] = provider
        query[::Entrance.config.auth_uid_attr] = uid
        ::Entrance.model.where(query).first
      end

      def set_auth_credentials(user, provider, uid)
        user[::Entrance.config.auth_provider_attr] = provider
        user[::Entrance.config.auth_uid_attr] = uid
      end

      def store_auth_credentials(user, provider, uid)
        set_auth_credentials(user, provider, uid)
        user.save && user
      end

      def create_user(name, email, provider, uid)
        data = {}
        data[::Entrance.config.name_attr] = name
        data[::Entrance.config.username_attr] = email
        user = ::Entrance.model.new(data)
        set_auth_credentials(user, provider, uid)

        if user.valid?
          return user.save && user
        else
          log "Invalid user: #{user.errors.to_a.join(', ')}"
        end
      end

      # authorizes or creates a user with the given oauth credentials.
      # does not check if user is banned or not (the /callback route does that)
      def auth_or_create(auth)
        provider, uid = auth['provider'], auth['uid']
        info = auth['info'] || {}

        log "Authenticating with #{provider}"

        # if running on production, make sure the provider is actually valid
        unless ::OmniAuth.config.test_mode
          raise "Invalid provider: #{provider}" unless can_authenticate_with?(provider)
        end

        if u = find_user_with_provider_and_uid(provider, uid)

          log "Authenticated! Provider: #{provider}, UID: #{uid}"
          return u

        else # no user with that provider/uid found
          name, email = info['name'], info['email']

          if email.present? and user = find_user_with_email(email)

            # if using different provider, it will update it
            log "Found user, but with different credentials."
            return store_auth_credentials(user, provider, uid)

          else

            log "Creating new user: '#{name}', email #{email}"
            name = name.is_a?(Array) ? name[0] : name

            return create_user(name, email, provider, uid)
          end

        end

      end # auth_or_create

    end

  end

end
