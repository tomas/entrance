class User < ActiveRecord::Base
  include Entrance::Model

  provides_entrance
end
