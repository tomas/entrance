%w(./app/models sinatra/base sinatra/flash entrance).each { |lib| require lib }

module Example

  class Routes < Sinatra::Base

    include Entrance::Controller
    register Sinatra::Flash

    set :sessions, :secret => 'veryverysecretkey'
    set :views, File.expand_path(File.dirname(__FILE__)) + '/views'

    before do
      login_required :except => ['/login', '/signup']
    end

    get '/' do
      erb :welcome
    end

    get '/signup' do
      erb :signup
    end

    post '/signup' do
      if @user = User.new(params[:user]) and @user.save
        flash[:success] = 'Signed up! Please log in now.'
        redirect to('/login')
      else
        flash[:error] = "Something's wrong. Try again."
        redirect to('/signup')
      end
    end

    get '/login' do
      if logged_in?
        redirect(to('/'))
      else
        erb :login
      end
    end

    post '/login' do
      if user = User.authenticate(params[:email], params[:password]) and user.active?
        remember = ['on', '1'].include?(params[:remember_me])
        login!(user, remember)

        flash[:success] = 'Welcome back!'
        redirect_to_stored_or to('/')
      else
        flash[:error] = "Couldn't log you in. Please try again."
        redirect to('/login')
      end
    end

    get '/logout' do
      logout!
      flash[:notice] = 'Logged out! See you soon.'
      redirect to('/login')
    end

  end

end
