Entrance
========

Clean, adaptable authentication library for Rails and Sinatra.

    $ gem install entrance

# Usage

``` rb
# in an intializer, e.g. config/initializers/entrance.rb

require 'entrance'

Entrance.configure do |config|
  config.access_denied_redirect_to = '/login'
  config.remember_for              = 1.month
  config.reset_password_window     = 2.hours
  config.cookie_secure             = Rails.env.production?
end

# in your controller

class ApplicationController < ActionController::Base
  include Entrance::Controller

  before_filter :login_required # provided by Entrance::Controller

  ...
end

# in your model

class User
  include Entrance::Model

  ... (setup fields)
  
  provides_entrance do |fields|
    fields.username = :email
    fields.password = :password
  end
end
```

Now, you're ready to roll.

``` rb
class SessionsController < ApplicationController

  skip_before_filter :login_required
  
  def new
    # render login form
  end

  def create
    if user = authenticate_and_login(params[:email], params[:password], params[:remember_me] == 'on')
      redirect_to '/app'
    else
      redirect_to '/login', :notice => "Invalid credentials."
    end
  end

end
```

If you need more control, -- like checking a users state before letting him in -- you can call directly the model's `.authenticate` method, and then call the `login!` method once you're ready.

``` rb
  def create
    if user = User.authenticate(params[:email], params[:password]) and user.active?
      login!(user, params[:remember_me] == '1')
      redirect_to '/app'
    else
      redirect_to '/login', :notice => "Invalid credentials."
    end
  end
```

As you can see, Entrance comes with out-of-box support for the "remember me" option. It also supports the usual 'reset password' token/email logic, but that's it. That's as far as Entrance goes -- we want to keep things simple and lean.

## Entrance::Config

All available options, along with their defaults.

``` rb
Entrance.configure do |config|
  # strategies
  config.cipher                     = Entrance::Ciphers::BCrypt # can also be Entrance::Ciphers::SHA1
  config.secret                     = nil
  config.stretches                  = 10

  # access denied
  config.access_denied_redirect_to  = '/login'
  config.access_denied_message_key  = nil # e.g. 'messages.access_denied'

  # reset password
  config.reset_password_mailer      = 'UserMailer'
  config.reset_password_method      = 'reset_password_request'
  config.reset_password_window      = 60 * 60 # 1.hour

  # remember me & cookies
  config.remember_for               = 60 * 24 * 14 # 2.weeks
  config.cookie_domain              = nil
  config.cookie_secure              = true
  config.cookie_path                = '/'
  config.cookie_httponly            = false
end
```

## Entrance::Fields

As declared in your model. Options and their defaults are:

``` rb
provides_entrance do |fields|
  # base
  fields.unique_key      = 'id' 
  fields.salt            = nil # only required for SHA1 strategy

  # username & password
  fields.name            = 'name' # only used by omniauth addon
  fields.username        = 'email'
  fields.password        = 'password_hash'

  # remember and reset
  fields.remember_token  = 'remember_token'
  fields.remember_until  = 'remember_token_expires_at'
  fields.reset_token     = 'reset_token'
  fields.reset_until     = 'reset_token_expires_at'

  # omniauth
  fields.auth_provider   = 'auth_provider'
  fields.auth_uid        = 'auth_uid'
end
```

## Entrance::Controller

When including it into your controller, this module will provide the following methods:
  
 - authenticate_and_login(username, password, remember_me = false)
 - login!(user, remember_me = false)
 - logout!

And the following helpers: 

 - current_user 
 - login_required
 - logged_in?
 - logged_out?
  
## Entrance::Model

Provides:

 - .provides_entrance(&block)
 - .authenticate(username, password)
 - .with_password_reset_token(token)
 - #password and #password=(value)
 - #remember_me! and #forget_me!  (unless remember_attr is set to nil)
 - #request_password_reset! (unless reset_attr is set to nil)

Examples
========

Thought you might ask. There's a full example Rails app and a Sinatra app in the examples folder. Check them out. 
 
Author
======

Written by Tomás Pollak.

Copyright
=========

(c) Fork, Ltd. MIT Licensed.
