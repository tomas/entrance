module Entrance

  module Controller

    def self.included(base)
      base.send(:helper_method, :current_user, :logged_in?, :logged_out?) if base.respond_to?(:helper_method)
    end

    def authenticate_and_login(username, password, remember_me = false)
      if user = Doorman.config.model.constantize.authenticate(username, password)
        login!(user, remember_me)
        user
      end
    end

    def login!(user, remember_me = false)
      self.current_user = user
      remember_or_forget(remember_me)
    end

    def logout!
      if logged_in?
        current_user.forget_me!
        self.current_user = nil
      end
      delete_remember_cookie
    end

    def login_required
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

    def current_user=(new_user)
      raise "Invalid user: #{new_user}" unless new_user.nil? or new_user.is_a?(Doorman.config.model.constantize)
      session[:user_id] = new_user ? new_user.id : nil
      @current_user = new_user # should be nil when logging out
    end

    def remember_or_forget(remember_me)
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
        render :nothing => true, :status => 401
      else
        flash[:notice] = I18n.t(Doorman.config.access_denied_message_key)
        redirect_to Doorman.config.access_denied_redirect_to
      end
    end

    def login_from_session
      self.current_user = User.find(session[:user_id]) if session[:user_id]
    end

    def login_from_cookie
      return unless cookies[REMEMBER_ME_TOKEN]

      query = {}
      query[Doorman.config.remember_token_attr] = cookies[REMEMBER_ME_TOKEN]
      if user = User.where(query).first \
        and user.send(Doorman.config.remember_until_attr) > Time.now
          self.current_user = user
          # user.update_remember_token_expiration!
          user
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_to_stored_or(default_path)
      redirect_to(session[:return_to] || default_path)
      session[:return_to] = nil
    end

    def redirect_to_back_or(default_path)
      redirect_to(request.env['HTTP_REFERER'] || default_path)
    end

    def set_remember_cookie
      values = {
        :expires  => Doorman.config.remember_for.from_now,
        :httponly => Doorman.config.cookie_httponly,
        :path     => Doorman.config.cookie_path,
        :secure   => Doorman.config.cookie_secure,
        :value    => current_user.send(Doorman.config.remember_token_attr)
      }
      values[:domain] = Doorman.config.cookie_domain if Doorman.config.cookie_domain

      cookies[REMEMBER_ME_TOKEN] = values
    end

    def delete_remember_cookie
      cookies.delete(REMEMBER_ME_TOKEN)
      # cookies.delete(REMEMBER_ME_TOKEN, :domain => AppConfig.cookie_domain)
    end

#    def cookies
#      @cookies ||= @env['action_dispatch.cookies'] || Rack::Request.new(@env).cookies
#    end

  end

end