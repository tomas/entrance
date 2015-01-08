require 'entrance/controller'
require 'entrance/model'
require 'entrance/ciphers'
require 'entrance/config'

require 'active_support/core_ext/numeric/time'

module Entrance

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
    config.validate!
  end

  def self.model
    @model ||= config.model.constantize
  end

  def self.generate_token(length = 40)
    str = SecureRandom.hex(length/2)
    return str unless str.respond_to?(:encode)
    str.encode('UTF-8')
  end

end
