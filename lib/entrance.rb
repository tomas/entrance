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
