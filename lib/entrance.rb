####################################
# Entrance
#
# By Tomas Pollak
# Simple Ruby Authentication Library
###################################

=begin

In your controller:
  include Entrance::Controller

  - Provides authenticate_and_login, login!(user), logout! methods
  - Provices login_required, logged_in? and logged_out? helpers

In your model:

  include Entrance::Model

  - Provides Model.authenticate(username, password)
  - Provices Model#remember_me! and Model#forget_me!
  - Provides Model#password getter and setter
  - Provides Model#request_password_reset!
=end

require 'entrance/controller'
require 'entrance/model'
require 'entrance/ciphers'

require 'active_support/core_ext/numeric/time'

module Entrance

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end

  def self.generate_token(length = 40)
    SecureRandom.hex(length/2).encode('UTF-8')
  end

end
