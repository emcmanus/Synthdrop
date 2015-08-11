class ProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:info] = "Changes saved."
    end
    redirect_to :edit_profile
  end

  private
  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:keyboard)
  end
end
