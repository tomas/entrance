require 'entrance'
require 'erb'

=begin

Simple login/signup support for sinatra. This extension
expects a login.erb and a signup.erb (unless disabled) to
be present in a views/public directory.

Once a user logs in, he or she will be redirected to /.

require 'sinatra/base'
require 'entrance/addons/sinatra'

class Hello < Sinatra::Base
  register Entrance::Sinatra

  before do
    login_required :except => ['/login', '/signup'] # or just /login if you don't want signups
  end
end

=end

module Entrance

  module Sinatra

    def self.registered(app)

      app.send(:include, ::Entrance::Controller)

      app.get '/login' do
        if logged_in?
          redirect(to('/'))
        else
          erb :'public/login'
        end
      end

      app.post '/login' do
        remember = ['on', 'true', '1'].include?(params[:remember])
        if params[:username].blank? or params[:password].blank?
          redirect_with('/login', :error, "Both fields are required.")
        elsif user = authenticate_and_login(params[:username], params[:password], remember)
          flash[:success] = 'Welcome back!'
          redirect_to_stored_or(to('/'))
        else
          redirect_with('/login', :error, "Couldn't log you in. Please try again.")
        end
      end

      app.get '/logout' do
        logout!
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
