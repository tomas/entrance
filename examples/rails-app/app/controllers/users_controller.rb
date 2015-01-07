class UsersController < ApplicationController

  skip_before_filter :login_required

  def new
    @user = User.new
  end

  def create
    if @user = User.new(user_params) and @user.save
      redirect_to :login, :notice => 'Signed up! Please log in now.'
    else
      flash[:error] = "Something's wrong. Try again."
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

end