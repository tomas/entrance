module Entrance

  module Controller
    
    REMEMBER_ME_TOKEN = 'auth_token'.freeze

    def self.included(base)
      base.send(:helper_method, :current_user, :logged_in?, :logged_out?) if base.respond_to?(:helper_method)
    end

    def authenticate_and_login(username, password, remember_me = false)
      if user = Entrance.model.authenticate(username, password)
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
      return if opts[:except] and opts[:except].include?(request.path_info)
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
      session[:user_id] = new_user ? new_user.send(Entrance.config.unique_key) : nil
      @current_user = new_user # should be nil when logging out
    end

    def remember_or_forget(remember_me)
      Entrance.config.permit!(:remember)

      if remember_me
        current_user.remember_me!
        set_remember_cookie
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
      query[Entrance.config.unique_key] = session[:user_id]
      self.current_user = Entrance.model.where(query).first if session[:user_id]
    end

    def login_from_cookie
      return unless Entrance.config.can?(:remember) && request.cookies[REMEMBER_ME_TOKEN]

      query = {}
      query[Entrance.config.remember_token_attr] = request.cookies[REMEMBER_ME_TOKEN]
      if user = Entrance.model.where(query).first \
        and user.send(Entrance.config.remember_until_attr) > Time.now
          self.current_user = user
          # user.update_remember_token_expiration!
          user
      end
    end

    def store_location
      session[:return_to] = request.fullpath
    end

    def redirect_to_stored_or(default_path)
      common_redirect(session[:return_to] || default_path)
      session[:return_to] = nil
    end

    def redirect_to_back_or(default_path)
      common_redirect(request.env['HTTP_REFERER'] || default_path)
    end

    def set_remember_cookie
      values = {
        :expires  => Entrance.config.remember_for.from_now,
        :httponly => Entrance.config.cookie_httponly,
        :path     => Entrance.config.cookie_path,
        :secure   => Entrance.config.cookie_secure,
        :value    => current_user.send(Entrance.config.remember_token_attr)
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
      if respond_to?(:cookie)
        cookies[name] = cookie
      else
        response.set_cookie(name, cookie)
      end
    end

    def delete_cookie!(name)
      if respond_to?(:cookie)
        cookies.delete(name)
      else
        response.delete_cookie(name)
      end
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
        flash[:notice] = 'Access denied.'
      end
    end

    def common_redirect(url)
      if respond_to?(:redirect)
        redirect(to(url)) # sinatra
      else
        redirect_to(url)  # rails
      end
    end

  end

end