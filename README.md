Entrance
========

Clean, adaptable authentication library for Rails and Sinatra.

   $ gem install entrance

# Usage

``` rb
# in an intializer, e.g. config/initializers/entrance.rb

require 'entrance'

Entrance.configure do |config|
  config.username_attr             = 'email'
  config.password_attr             = 'password_hash'
  config.secret                    = 'some-long-and-very-secret-key'
  config.reset_password_window     = 1.hour
  config.remember_for              = 2.weeks
end

# in your controller

class ApplicationController < ActionController::Base
  include Entrance::Controller

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
class SessionsController < ApplicationController

  def create
    if user = User.authenticate(params[:email], params[:password]) and user.active?
      login!(user, (params[:remember_me] == '1'))
      redirect_to '/app'
    else
      redirect_to :new, :notice => "Invalid credentials."
    end
  end

end
```

# Entrance::Config

All available options, along with their defaults.

``` rb
Entrance.configure do |config|
  config.model                 = 'User'
  config.mailer_class          = 'UserMailer'
  config.cipher                = Ciphers::BCrypt
  config.secret                = nil
  config.stretches             = 1
  config.username_attr         = 'email'
  config.password_attr         = 'password_hash'
  config.salt_attr             = nil
  config.remember_token_attr   = 'remember_token'
  config.remember_until_attr   = 'remember_token_expires_at'
  config.reset_token_attr      = 'reset_token'
  config.reset_until_attr      = 'reset_token_expires_at'
  config.access_denied_redirect_to  = '/'
  config.access_denied_message_key = 'messages.access_denied'
  config.reset_password_window = 1.hour
  config.remember_for          = 2.weeks
  config.cookie_domain         = nil
  config.cookie_secure         = true
  config.cookie_path           = '/'
  config.cookie_httponly       = false
end

# Entrance::Controller

When including it into your controller, this module will provide the following methods:
  
 - authenticate_and_login
 - login!(user)
 - logout!

And the following helpers: 

 - login_required
 - logged_in?
 - logged_out?
  
# Entrance::Model

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
 