module Entrance

  module Controller

    REMEMBER_ME_TOKEN = 'auth_token'.freeze

    module ClassMethods

      # lets us do app.skip_paths.push('/specific/path/we/want/unprotected')
      def allow_paths
        @allow_paths ||= []
      end

    end

    def self.included(base)
      base.send(:helper_method, :current_user, :logged_in?, :logged_out?) if base.respond_to?(:helper_method)
      base.extend(ClassMethods)
    end

    def authenticate_and_login(username, password, remember_me = false)
      if user = Entrance.model.authenticate(username, password) \
        and (!user.respond_to?(:can_login?) || user.can_login?)
          login!(user, remember_me)
          user
      end
    end

    def login!(user, remember_me = false)
      self.current_user = user
      remember_or_forget(remember_me) if Entrance.config.can?(:remember)
    end

    def logout!
      if logged_in?
        current_user.forget_me! if Entrance.config.can?(:remember)
        self.current_user = nil
      end
      delete_remember_cookie if Entrance.config.can?(:remember)
    end

    def login_required(opts = {})
      allowed = (opts[:except] || []) + self.class.allow_paths
      return if allowed.any? and allowed.include?(request.path_info)
      logged_in? || access_denied
    end

    def current_user
      @current_user ||= (login_from_session || login_from_cookie)
    end

    def logged_in?
      !!current_user
    end

    def logged_out?
      !logged_in?
    end

    private

    # new_user may be nil (when logging out) or an instance of the Entrance.model class
    def current_user=(new_user)
      raise "Invalid user: #{new_user}" unless new_user.nil? or new_user.is_a?(Entrance.model)
      session[:user_id] = new_user ? new_user.send(Entrance.fields.unique_key) : nil
      @current_user = new_user # should be nil when logging out
    end

    def remember_or_forget(remember_me)
      Entrance.config.permit!(:remember)

      if remember_me
        token = current_user.remember_me!
        set_remember_cookie(token) if token
      else
        current_user.forget_me!
        delete_remember_cookie
      end
    end

    def access_denied
      store_location
      if request.xhr?
        return_401
      else
        set_flash_message if respond_to?(:flash)
        common_redirect(Entrance.config.access_denied_redirect_to)
      end
    end

    def login_from_session
      query = {}
      query[Entrance.fields.unique_key] = session[:user_id]
      self.current_user = Entrance.model.where(query).first if session[:user_id]
    end

    def login_from_cookie
      return unless Entrance.config.can?(:remember) && request.cookies[REMEMBER_ME_TOKEN]

      query = {}
      query[Entrance.fields.remember_token] = request.cookies[REMEMBER_ME_TOKEN]
      if user = Entrance.model.where(query).first \
        and user.send(Entrance.fields.remember_until) > Time.now
          self.current_user = user
          # user.update_remember_token_expiration!
          user
      end
    end

    def store_location
      path = request.fullpath
      session[:return_to] = path unless ['/favicon.ico'].include?(path)
    end

    def redirect_to_stored_or(default_path)
      stored = session.delete(:return_to)
      common_redirect(stored || default_path, true)
    end

    def redirect_to_back_or(default_path)
      common_redirect(request.env['HTTP_REFERER'] || default_path)
    end

    def set_remember_cookie(token)
      values = {
        :expires  => Time.now + Entrance.config.remember_for.to_i,
        :httponly => Entrance.config.cookie_httponly,
        :path     => Entrance.config.cookie_path,
        :secure   => Entrance.config.cookie_secure,
        :value    => token
      }
      values[:domain] = Entrance.config.cookie_domain if Entrance.config.cookie_domain

      set_cookie!(REMEMBER_ME_TOKEN, values)
    end

    def delete_remember_cookie
      delete_cookie!(REMEMBER_ME_TOKEN)
    end

    ############################################
    # compat stuff between rails & sinatra

    def set_cookie!(name, cookie)
      response.set_cookie(name, cookie)
    end

    def delete_cookie!(name)
      response.delete_cookie(name)
    end

    def return_401
      if respond_to?(:halt) # sinatra
        halt(401)
      else # rails
        render :nothing => true, :status => 401
      end
    end

    def set_flash_message
      return unless respond_to?(:flash)

      if Entrance.config.access_denied_message_key
        flash[:notice] = I18n.t(Entrance.config.access_denied_message_key)
      else
        flash[:notice] = 'Please log in first.'
      end
    end

    def redirect_with(url, type, message)
      flash[type] = message if respond_to?(:flash)
      common_redirect(url)
    end

    # when redirecting to stored_path
    def common_redirect(url, with_base = false)
      if respond_to?(:redirect)
        return with_base ? redirect(url) : redirect(to(url)) # sinatra
      else
        redirect_to(url)  # rails
      end
    end

  end

end
