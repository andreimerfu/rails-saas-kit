class InvitationsController < ApplicationController
  layout "devise" # Use the devise layout for invitation acceptance forms

  before_action :authenticate_user!, only: [ :update ] # Authenticate for password setting, not initial link click

  def edit
    @user = User.find_by_invitation_token(params[:token])

    if @user && @user.invitation_token_valid?
      if @user.organization.enterprise_login_configured?
        sign_in(@user)
        redirect_to authenticated_root_path, notice: "Welcome! You have been logged in."
      else
        # Redirect to password setting form
        render :edit
      end
    else
      redirect_to unauthenticated_root_path, alert: "Invalid or expired invitation token."
    end
  end

  def update
    @user = User.find_by_invitation_token(params[:user][:invitation_token])

    if @user && @user.invitation_token_valid?
      if @user.accept_invitation_with_password(user_params)
        sign_in(@user)
        redirect_to authenticated_root_path, notice: "Welcome! Your password has been set."
      else
        # Handle validation errors on password setting
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to unauthenticated_root_path, alert: "Invalid or expired invitation token."
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :invitation_token)
  end
end
