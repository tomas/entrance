require 'rubygems'
require 'bundler/setup'
require 'active_model/serializers'
require 'mongo_mapper'
require 'entrance'

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database   = 'entrance-example'

Entrance.configure do |config|
  config.remember_for  = 1.month
  config.cookie_secure = false # for testing
end

class User
  include MongoMapper::Document
  include Entrance::Model

  key :state, :default => 'active'

  key :name
  key :email, :unique => true
  key :password_hash

  key :remember_token
  key :remember_token_expires_at, Time

  key :reset_token
  key :reset_token_expires_at, Time

  provides_entrance

  def can_login?
    state.to_sym == :active
  end

end
