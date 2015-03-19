require 'rubygems'
require 'bundler/setup'
require 'mongo_mapper'
require 'entrance'

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database   = 'entrance-omniauth-example'

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

  key :password_hash, String
  key :auth_provider, String
  key :auth_uid, String

  key :remember_token
  key :remember_token_expires_at, Time

  provides_entrance :local => false, :remote => true

  def active?
    state.to_sym == :active
  end

end