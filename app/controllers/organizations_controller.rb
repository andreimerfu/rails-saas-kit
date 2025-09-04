class OrganizationsController < ApplicationController
  layout "application", only: [ :manage ]

  before_action :authenticate_user!
  before_action :authorize_organization_management

  def manage
    @organization = current_user.organization
    @members = @organization.users # Assuming 'users' is the association for members
  end

  def update
    @organization = current_user.organization
    if @organization.update(organization_params)
      redirect_to manage_organization_path, notice: "Organization name updated successfully."
    else
      render :manage, status: :unprocessable_entity
    end
  end

  # invite action has been moved to Organizations::InvitationsController
  # pricing action has been moved to Organizations::PricingsController

  # create_checkout_session is handled by stripe-rails or a dedicated SubscriptionsController.

  private

  def organization_params
    params.require(:organization).permit(:name)
  end

  # invite_params has been moved to Organizations::InvitationsController

  def authorize_organization_management
    unless current_user&.is_owner_or_admin? # Assumes User model has is_owner_or_admin?
      redirect_to root_path, alert: "You are not authorized to manage organizations."
    end
  end
end
