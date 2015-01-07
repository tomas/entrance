class ApplicationController < ActionController::Base
  include Entrance::Controller

  before_filter :login_required
  protect_from_forgery with: :exception
end
