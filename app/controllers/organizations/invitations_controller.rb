class Organizations::InvitationsController < ApplicationController
  layout "devise" # Use the devise layout for invitation acceptance forms

  before_action :authenticate_user!, only: [ :create ] # Authenticate for creation
  after_action :verify_authorized, only: [ :create ]

  def create
    authorize current_user, :invite_member?

    Users::Invitation.call(invite_params) do |on|
      on.success { |payload| redirect_to manage_organization_path, notice: payload[:message] }
      on.failure { |failure_payload| redirect_to manage_organization_path, alert: failure_payload[:message] }
    end
  end

  def edit
    @user = User.find_by_invitation_token(params[:token], false)

    if @user && @user.invitation_token?
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

    if @user && @user.invitation_token?
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

  def invite_params
    params.require(:user).permit(:email).to_h.merge(
      inviter: current_user,
      organization: current_user.organization
    )
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :invitation_token)
  end
end
