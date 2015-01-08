require 'entrance/controller'
require 'entrance/model'
require 'entrance/ciphers'
require 'entrance/config'
require 'digest/sha1'

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
    str = Digest::SHA1.hexdigest([Time.now, rand].join)
    str[0..(length-1)]
  end

end
