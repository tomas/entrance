class User < ActiveRecord::Base
  include Entrance::Model
  
  validate_entrance! # ensures everything is in order, and sets up password validations
end
