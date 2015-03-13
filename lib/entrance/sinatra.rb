require 'entrance'

module Entrance

  module Sinatra

    def self.registered(app)

      app.include ::Entrance::Controller

      app.get '/login' do
        if logged_in?
          redirect(to('/'))
        else
          erb :'public/login'
        end
      end

      app.post '/login' do
        remember = ['on', 'true', '1'].include?(params[:remember])
        if user = authenticate_and_login(params[:username], params[:password], remember)
          flash[:success] = 'Welcome back!'
          redirect_to_stored_or(to('/'))
        else
          redirect_with('/login', :error, "Couldn't log you in. Please try again.")
        end
      end

      app.get '/logout' do
        kill_session!
        redirect_with('/login', :notice, 'Logged out! See you soon.')
      end

      app.get '/signup' do
        return redirect(to('/')) if logged_in?
        @user = ::Entrance.model.new
        erb :'public/signup'
      end

      app.post '/signup' do
        @user = ::Entrance.model.new(params[:user])
        if @user.valid? && @user.save
          redirect_with('/login', :success, "Account created! Please sign in to continue.")
        else
          flash[:error] = "Couldn't sign you up. Please try again."
          erb :'public/signup'
        end
      end

    end

  end

end
