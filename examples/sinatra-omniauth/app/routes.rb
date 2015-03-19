%w(./app/models sinatra/base sinatra/flash).each { |lib| require lib }

require 'entrance/addons/omniauth'
require 'omniauth-twitter'

module Example

  class Routes < Sinatra::Base

    register Sinatra::Flash
    register Entrance::OmniAuth

    set :sessions, :secret => 'veryverysecretkey'
    set :views, File.expand_path(File.dirname(__FILE__)) + '/views'

    set :auth_test, true     # only true for testing
    set :auth_remember, true # enables 'remember me' for omniauth logins
    set :auth_providers, {
      :twitter => {
        :key => 'foobar',
        :secret => 'xoxoxoxox'
      }
    }

    before do
      login_required :except => ['/login']
    end

    get '/' do
      erb :welcome
    end

    get '/login' do
      erb :login
    end

    get '/logout' do
      logout!
      flash[:notice] = 'Logged out! See you soon.'
      redirect to('/login')
    end

  end

end
