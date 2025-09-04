# app/controllers/organizations/members_controller.rb
module Organizations
  class MembersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_organization
    before_action :set_member, only: [ :destroy ]
    before_action :authorize_member_management # Specific authorization for member removal

    # DELETE /organization/members/:id
    def destroy
      if @member == current_user
        redirect_to manage_organization_path, alert: "You cannot remove yourself from the organization."
        return
      end

      # Business logic: deleting the user record.
      # Consider if there are other dependencies or cleanup needed before user deletion.
      # For example, reassigning records, handling subscriptions if the user was a payer, etc.
      # For now, a simple destroy.
      if @member.destroy
        redirect_to manage_organization_path, notice: "Member #{@member.email} has been removed and their account deleted."
      else
        error_message = @member.errors.full_messages.to_sentence
        redirect_to manage_organization_path, alert: "Could not remove member: #{error_message}"
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_organization_path, alert: "Member not found."
    rescue StandardError => e
      Rails.logger.error "Organizations::MembersController: Error destroying member - #{e.message}"
      redirect_to manage_organization_path, alert: "An unexpected error occurred while removing the member."
    end

    private

    def set_organization
      # Assuming the organization is identified by current_user.
      # If your routes were /organizations/:organization_id/members/:id, you'd use:
      # @organization = Organization.find(params[:organization_id])
      @organization = current_user.organization
      redirect_to root_path, alert: "Organization not found." unless @organization
    end

    def set_member
      # Members are users belonging to the current_user's organization.
      @member = @organization.users.find_by(id: params[:id])
      redirect_to manage_organization_path, alert: "Member not found in your organization." unless @member
    end

    def authorize_member_management
      # Authorize using the OrganizationPolicy's remove_member? method.
      # We pass @member to the policy method, and Pundit uses @organization as the record.
      authorize @organization, :remove_member? # Checks if current_user can remove members from @organization
    rescue Pundit::NotAuthorizedError
      redirect_to manage_organization_path, alert: "You are not authorized to manage members for this organization."
    end
  end
end
