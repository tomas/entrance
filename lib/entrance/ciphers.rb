require 'digest/sha1'
require 'bcrypt'

module Entrance

  module Ciphers

    module SHA1

      JOIN_STRING = '--'

      def self.read(password)
        password
      end

      # same logic as restful authentication
      def self.encrypt(password, salt)
        digest = Doorman.config.secret
        raise "Secret not set!" if digest.blank?

        Doorman.config.stretches.times do
          str = [digest, salt, password, Doorman.config.secret].join(JOIN_STRING)
          digest = Digest::SHA1.hexdigest(str)
        end

        digest
      end

    end

    module BCrypt

      def self.read(password)
        BCrypt::Password.new(password)
      end

      # same logic as restful authentication
      def self.encrypt(password, salt = nil)
        BCrypt::Password.create(password)
      end

    end

  end

end