Entrance
========

Clean, adaptable authentication library for Rails and Sinatra.

    $ gem install entrance

Still in early phase, but it works. BCrypt and SHA1 (a-la Restful Auth) encryption are supported.

# Usage

``` rb
# in an intializer, e.g. config/initializers/entrance.rb

require 'entrance'

Entrance.configure do |config|
  config.username_attr             = 'email'
  config.password_attr             = 'password_hash' # make sure you map the right attribute name
  config.access_denied_message_key = 'messages.access_denied'
  config.remember_for              = 1.month
end

# in your controller

class ApplicationController < ActionController::Base
  include Entrance::Controller

  before_filter :login_required

  ...
end

# in your model

class User
  include Entrance::Model

  ...
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
    if user = authenticate_and_login(params[:email], params[:password], params[:remember_me])
      redirect_to '/app'
    else
      redirect_to :new, :notice => "Invalid credentials."
    end
  end

end
```

If you need more control, you can call directly the model's `.authenticate` method.

``` rb
  def create
    if user = User.authenticate(params[:email], params[:password]) and user.active?
      remember = params[:remember_me] == '1'
      login!(user, remember)
      redirect_to '/app'
    else
      redirect_to :new, :notice => "Invalid credentials."
    end
  end
```

## Entrance::Config

All available options, along with their defaults.

``` rb
Entrance.configure do |config|
  config.model                      = 'User'
  config.cipher                     = Ciphers::BCrypt
  config.secret                     = nil
  config.stretches                  = 10
  config.salt_attr                  = nil
  config.username_attr              = 'email'
  config.password_attr              = 'password_hash'
  config.remember_token_attr        = 'remember_token'
  config.remember_until_attr        = 'remember_token_expires_at'
  config.reset_token_attr           = 'reset_token'
  config.reset_until_attr           = 'reset_token_expires_at'
  config.access_denied_redirect_to  = '/'
  config.access_denied_message_key  = nil
  config.reset_password_mailer      = 'UserMailer'
  config.reset_password_method      = 'reset_password_request'
  config.reset_password_window      = 1.hour
  config.remember_for               = 2.weeks
  config.cookie_domain              = nil
  config.cookie_secure              = true
  config.cookie_path                = '/'
  config.cookie_httponly            = false
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

 - .authenticate(username, password)
 - #remember_me! and #forget_me!
 - #password and #password=(value)
 - #request_password_reset!
 
Author
======

Written by Tomás Pollak.

Copyright
=========

(c) Fork, Ltd. MIT Licensed. 
 
