class Organizations::InvitationsController < ApplicationController
  layout "devise" # Use the devise layout for invitation acceptance forms

  before_action :authenticate_user!, only: [ :create, :update ] # Authenticate for creation and password setting

  def create
    # Ensure current_user and their organization are present
    unless current_user&.organization
      redirect_to root_path, alert: "Authentication error or organization not found."
      return
    end

    Users::Invitation.call(invite_params) do |on|
      on.success do |payload|
        redirect_to manage_organization_path, notice: payload[:message]
      end

      on.failure(:validation) do |failure_payload|
        # Construct a more user-friendly message from validation errors if possible
        error_message = if failure_payload[:errors].is_a?(Hash)
                          failure_payload[:errors].map { |field, messages| "#{field.to_s.humanize} #{messages.join(', ')}" }.join("; ")
        else
                          failure_payload[:message]
        end
        redirect_to manage_organization_path, alert: "Validation failed: #{error_message}"
      end

      on.failure(:conflict) do |failure_payload|
        redirect_to manage_organization_path, alert: "Could not invite user: #{failure_payload[:message]}"
      end

      on.failure(:invitation_failed) do |failure_payload|
        redirect_to manage_organization_path, alert: "Failed to send invitation: #{failure_payload[:message]}"
      end

      on.failure do |failure_payload| # Catch-all for other failure types
        Rails.logger.error "User Invitation Failure: #{failure_payload.inspect}"
        alert_message = failure_payload.is_a?(Hash) && failure_payload[:message] ? failure_payload[:message] : "An unexpected error occurred while sending the invitation."
        redirect_to manage_organization_path, alert: alert_message
      end
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
