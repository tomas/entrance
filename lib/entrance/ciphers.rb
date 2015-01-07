require 'digest/sha1'
require 'bcrypt'

module Entrance

  module Ciphers

    module SHA1

      JOIN_STRING = '--'

      def self.match?(stored, given, salt = nil)
        stored === encrypt(given, salt)
      end

      # same logic as restful authentication
      def self.encrypt(password, salt)
        digest = Entrance.config.secret
        raise "Secret not set!" if digest.blank?

        Entrance.config.stretches.times do
          str = [digest, salt, password, Entrance.config.secret].join(JOIN_STRING)
          digest = Digest::SHA1.hexdigest(str)
        end

        digest
      end

    end

    module BCrypt

      # https://github.com/codahale/bcrypt-ruby
      def self.match?(stored, given, salt = nil)
        ::BCrypt::Password.new(stored) == given
        # ::BCrypt::Password.new(stored) == encrypt(given)
      end

      def self.encrypt(password, salt = nil)
        ::BCrypt::Password.create(password)
      end

    end

  end

end