require 'active_support/concern'

module Model
  extend ActiveSupport::Concern

  included do
    # verify that username/password attributes are present
    attrs = Entrance.config.model.constantize.columns.collect(&:name)
    %w(username_attr password_attr).each do |key|
      attr = Entrance.config.send(key)
      raise "Couldn't find '#{attr}' in #{Entrance.config.model} model." unless attrs.include?(attr)
    end

    validates :password, :presence => true, :length => 6..32, :if => :password_required?
    validates :password, :confirmation => true, :if => :password_required?
    validates :password_confirmation, :presence => true, :if => :password_required?
  end

  module ClassMethods

    def authenticate(username, password)
      return if username.blank? or password.blank?

      query = {}
      query[Entrance.config.username_attr] = username.downcase.strip
      if u = where(query).first
        return u.authenticated?(password) ? u : nil
      end
    end

    def with_password_reset_token(token)
      return if token.blank?

      query = {}
      query[Entrance.config.reset_token_attr] = token.strip
      if u = where(query).first \
        and (!Doorman.config.reset_until_attr || u.send(Doorman.config.reset_until_attr) > Time.now)
          return u
      end
    end

  end

  def authenticated?(string)
    password === encrypt_password(string)
  end

  def remember_me!(until_date = nil)
    update_attribute(Entrance.config.remember_token_attr, Entrance.generate_token)
    update_remember_token_expiration!(until_date)
  end

  def update_remember_token_expiration!(until_date = nil)
    timestamp = until_date || Entrance.config.remember_for
    update_attribute(Entrance.config.remember_until_attr, timestamp.from_now)
  end

  def forget_me!
    update_attribute(Entrance.config.remember_token_attr, nil)
    update_attribute(Entrance.config.remember_until_attr, nil)
  end

  def password
    @password || Entrance.config.cipher.read(send(Entrance.config.password_attr))
  end

  def password=(new_password)
    return if new_password.blank?

    @password = new_password # for validation
    @password_changed = true

    # if we're using salt and it is empty, generate one
    if Entrance.config.salt_attr \
      and send(Entrance.config.salt_attr).blank?
        self.send(Entrance.config.salt_attr + '=', Entrance.generate_token)
    end

    self.send(Entrance.config.password_attr + '=', encrypt_password(new_password))
  end

  def request_password_reset!
    send(Entrance.config.reset_token_attr + '=', Entrance.generate_token)
    if Doorman.config.reset_until_attr
      update_attribute(Entrance.config.reset_until_attr, Entrance.config.reset_password_window.from_now)
    end
    if save(:validate => false)
      method = Entrance.config.reset_password_method
      Entrance.config.reset_password_mailer.constantize.send(method, self).deliver
    end
  end

  private

  def get_salt
    Entrance.config.salt_attr && send(Entrance.config.salt_attr)
  end

  def encrypt_password(string)
    Entrance.config.cipher.encrypt(string, get_salt)
  end

  def password_required?
    password.blank? or @password_changed
  end

end