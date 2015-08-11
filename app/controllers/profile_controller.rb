class ProfileController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :rc
  before_action :authenticate_user!
  before_action :set_user

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:info] = "Changes saved."
      redirect_to :edit_profile
    else
      render action: :edit
    end
  end

  def rc
    render js: (@user.rc || "")
  end

  private
  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:keyboard, :rc)
  end
end
