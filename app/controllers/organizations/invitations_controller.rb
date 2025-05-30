class Organizations::InvitationsController < ApplicationController
  layout "devise" # Use the devise layout for invitation acceptance forms

  before_action :authenticate_user!, only: [ :create ] # Authenticate for creation
  skip_before_action :authenticate_user!, only: [ :edit, :update ] # Skip authentication for accepting invitations
  skip_before_action :check_user_onboarding_status, only: [ :edit, :update ] # Skip onboarding check
  after_action :verify_authorized, only: [ :create ]

  def create
    authorize current_user, :invite_member?

    Users::Invitation.call(invite_params) do |on|
      on.success { |payload| redirect_to manage_organization_path, notice: payload[:message] }
      on.failure { |failure_payload| redirect_to manage_organization_path, alert: failure_payload[:message] }
    end
  end

  def edit
    @user = User.find_by_invitation_token(params[:token], true) # true to check if token is valid

    if @user.nil?
      redirect_to unauthenticated_root_path, alert: "Invalid or expired invitation token."
      return
    end

    # If organization has SSO configured, auto-accept the invitation
    if @user.organization&.enterprise_login_configured?
      if @user.accept_invitation_without_password!
        # Redirect to SSO login
        flash[:notice] = "Your invitation has been accepted. Please log in with your company SSO."
        redirect_to new_user_session_path(email: @user.email)
      else
        Rails.logger.error "Failed to accept invitation for user #{@user.email}: #{@user.errors.full_messages.join(', ')}"
        redirect_to unauthenticated_root_path, alert: "Failed to accept invitation. Please contact support."
      end
    else
      # Show password setting form for non-SSO organizations
      @token = params[:token]
      render :edit
    end
  end

  def update
    @user = User.find_by_invitation_token(params[:user][:invitation_token], true)

    if @user.nil?
      redirect_to unauthenticated_root_path, alert: "Invalid or expired invitation token."
      return
    end

    # Only allow password setting for non-SSO organizations
    if @user.organization&.enterprise_login_configured?
      redirect_to new_user_session_path, alert: "Please use your company SSO to log in."
      return
    end

    if @user.accept_invitation_with_password(user_params)
      sign_in(@user)
      redirect_to authenticated_root_path, notice: "Welcome! Your password has been set and you are now signed in."
    else
      @token = params[:user][:invitation_token]
      render :edit, status: :unprocessable_entity
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
