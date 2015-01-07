class SessionsController < ApplicationController

  skip_before_filter :login_required

  def new
    # renders login form
  end

  def create
    remember = ['on', 'true'].include?(params[:remember_me])
    puts "Should remember: #{remember}"
    if user = authenticate_and_login(params[:email], params[:password], remember)
      redirect_to :root
    else
      flash.now[:error] = 'Invalid credentials.'
      render :new
    end
  end

  def destroy
    logout!
    redirect_to :login, :notice => 'Logged out! See you soon.'
  end

end