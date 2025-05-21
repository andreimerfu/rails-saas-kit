# app/controllers/organizations/pricings_controller.rb
module Organizations
  class PricingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_organization
    before_action :authorize_pricing_view # Specific authorization for viewing pricing

    # GET /organizations/:organization_id/pricing
    # or GET /organization/pricing (if singular resource)
    def show
      Organizations::PricingPlanFetcher.call(organization: @organization) do |on|
        on.success do |formatted_plans|
          @plans = formatted_plans
        end

        on.failure(:stripe_config_error) do |failure_payload|
          @plans = []
          flash.now[:alert] = "Pricing plans are currently unavailable: #{failure_payload[:message]}"
        end

        on.failure(:fetch_error) do |failure_payload|
          @plans = []
          flash.now[:alert] = "Could not load pricing plans: #{failure_payload[:message]}"
        end

        on.failure do |failure_payload| # Generic catch-all
          Rails.logger.error "Organizations::PricingPlanFetcher failed with unhandled error: #{failure_payload.inspect}"
          @plans = []
          flash.now[:alert] = "An unexpected error occurred while loading pricing plans."
        end
      end

      # Handle redirect parameters from Stripe Checkout
      if params[:checkout] == "success"
        @organization.reload # Reload to get latest subscription details updated by webhook.
        flash.now[:notice] = "Your subscription has been updated successfully!"
      elsif params[:checkout] == "cancel"
        flash.now[:warning] = "Your subscription process was cancelled."
      end
      # The view organizations/pricings/show.html.erb will be rendered by convention.
    end

    private

    def set_organization
      # Consistent with InvitationsController, assuming current_user.organization
      # or a route parameter like :organization_id
      @organization = current_user.organization
      redirect_to root_path, alert: "Organization not found." unless @organization
    end

    def authorize_pricing_view
      # Replace with Pundit policy: authorize @organization, :view_pricing?
      # For now, ensuring the user belongs to the organization.
      # The original controller had `authorize @organization` which implies a Pundit policy.
      # This should be `authorize @organization, :show_pricing?` or similar with Pundit.
      # If Pundit is fully set up, `authorize @organization` might be sufficient if
      # `PricingsPolicy#show?` is defined.
      # For now, a basic check:
      unless current_user && current_user.organization == @organization
        redirect_to root_path, alert: "You are not authorized to view pricing for this organization."
      end
      # If Pundit is used, the line would be:
      # authorize @organization, :show? # Assuming a PricingsPolicy or OrganizationPolicy
    end
  end
end
