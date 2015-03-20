require 'entrance/controller'
require 'entrance/model'
require 'entrance/ciphers'
require 'entrance/config'
require 'entrance/fields'
require 'digest/sha1'

module Entrance

  def self.config
    @config ||= Config.new
  end

  def self.model
    @model ||= get_class(config.model)
  end

  def self.fields
    @fields ||= Fields.new
  end

  def self.configure
    yield config
    config.validate!
  end

  def self.generate_token(length = 40)
    str = Digest::SHA1.hexdigest([Time.now, rand].join)
    str[0..(length-1)]
  end

  private

  def self.get_class(str)
    str.split('::').inject(Object) { |mod, name| mod.const_get(name) }
  end

end
