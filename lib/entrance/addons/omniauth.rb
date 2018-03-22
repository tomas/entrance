require 'entrance'
require 'omniauth'

=begin

require 'sinatra/base'
require 'omniauth-twitter'
require 'entrance/addons/omniauth'

class Hello < Sinatra::Base
  register Entrance::OmniAuth

  set :sessions, true
  set :auth_test, false    # only true for testing
  set :auth_remember, true # enables 'remember me' for omniauth logins
  set :auth_redirect, '/'  # where to redirect on successful login
  set :auth_providers, {
    :twitter => {
      :key => 'foobar'
    }
  }
end

=end

module Entrance

  module OmniAuth

    class << self

      def providers
        @providers ||= []
      end

      def registered(app)

        app.send(:include, Entrance::Controller) # provides redirects, etc

        app.use ::OmniAuth::Builder do
          # this is run only once after the app has initialized, so it's safe to set it here.
          if app.settings.respond_to?(:auth_test)
            ::OmniAuth.config.test_mode = true if app.settings.auth_test?
          end

          app.settings.auth_providers.each do |name, options|
            # puts "Initializing #{name} provider: #{options.inspect}"
            opts = options || {}
            provider(name, opts[:key], opts[:secret], opts[:extra] || {})

            app.allow_paths.push("/auth/#{name}/callback")
            ::Entrance::OmniAuth.providers.push(name.to_sym)
          end
        end

        # make _method=delete work in POST requests:
        app.enable :method_override

        [:get, :post].each do |action|

          app.send(action, '/auth/:provider/callback') do
            auth   = request.env['omniauth.auth']
            params = request.env["omniauth.params"]
            unless user = ::Entrance::OmniAuth.auth_or_create(auth, params)
              # return return_401
              redirect_with(Entrance.config.access_denied_redirect_to, :error, 'Unable to create record for new user. Check the log file.')
            end

            if ::Entrance::OmniAuth.valid_user?(user)
              login!(user, app.settings.auth_remember)
              flash[:success] = 'Welcome back!' if respond_to?(:flash)
              redirect_to_stored_or(to(app.settings.auth_redirect))
            else
              redirect_with(Entrance.config.access_denied_redirect_to, :error, 'Unable to authenticate. Please try again.')
            end
          end

        end # get, post

        app.get '/auth/failure' do
          redirect_with(Entrance.config.access_denied_redirect_to, :error, params[:message])
        end

        app.allow_paths.push("/auth/failure")

      end # registered

      def logger
        @logger ||= Logger.new('./log/omniauth.log')
      end

      def log(str)
        logger.info(str) rescue nil
      end
      
      def omniauth_params
        @omniauth_params
      end

      def valid_user?(user)
        if user.respond_to?(:can_login?) and !user.can_login?
         return false
        end
        user.valid?
      end

      def can_authenticate_with?(service)
        return true if ::OmniAuth.config.test_mode and service.to_sym == :default
        ::Entrance::OmniAuth.providers.include?(service.to_sym)
      end

      def find_user_with_username(username)
        query = {}
        query[::Entrance.fields.username] = username # .to_s.downcase.strip
        scoped_model.where(query).first
      end

      def find_user_with_provider_and_uid(provider, uid)
        query = {}
        query[::Entrance.fields.auth_provider] = provider
        query[::Entrance.fields.auth_uid] = uid
        scoped_model.where(query).first
      end

      def set_auth_credentials(user, provider, uid)
        user[::Entrance.fields.auth_provider] = provider
        user[::Entrance.fields.auth_uid] = uid
      end

      def store_auth_credentials(user, provider, uid)
        set_auth_credentials(user, provider, uid)
        user.save && user
      end

      def create_user(name, email, provider, uid)
        data = {}
        data[::Entrance.fields.name] = name
        data[::Entrance.fields.username] = email
        user = scoped_model.new(data)
        set_auth_credentials(user, provider, uid)

        if user.valid?
          return user.save && user
        else
          log "Invalid user: #{user.errors.to_a.join(', ')}"
          false
        end
      end

      # authorizes or creates a user with the given oauth credentials.
      # does not check if user is banned or not (the /callback route does that)
      def auth_or_create(auth, params = {})
        @omniauth_params = params
        
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

          if email.present? and user = find_user_with_username(email)

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
