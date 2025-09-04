class OnboardingController < ApplicationController
  include Wicked::Wizard

  # Define the steps in the wizard
  steps :welcome, :organization_details, :complete # :complete is a final display step

  # Ensure user is logged in for all onboarding steps
  before_action :authenticate_user!
  # This filter redirects if user already has an organization, except for the 'complete' step.
  before_action :ensure_no_organization_for_wizard, except: [ :show, :update ] # Adjusted for wicked's show/update
  # This filter ensures an organization exists if trying to access 'complete' directly.
  before_action :ensure_organization_exists_for_complete, only: [ :show ] # Applied only when step is :complete

  # GET /onboarding/:step
  def show
    case step
    when :welcome
      # No specific data needed for welcome, just render the view.
    when :organization_details
      @organization = Organization.new # For the form
    when :complete
      # Ensure organization exists for the complete step, handled by before_action
      # If a user lands here, they should have an organization.
      @organization = current_user.organization
      redirect_to welcome_onboarding_index_path, alert: "Organization not yet created." if @organization.nil? && wizard_steps.first != :complete
    end
    render_wizard # Renders app/views/onboarding/STEP.html.erb
  end

  # PUT /onboarding/:step
  # PATCH /onboarding/:step
  def update
    case step
    when :organization_details
      @organization = Organization.new(organization_params)
      @organization.domain = request.domain # Or derive from current_user if more appropriate

      if @organization.save
        current_user.update!(organization: @organization, role: :owner)
        # Wicked will automatically try to redirect to the next step's #show action
        # If this is the last step before 'complete', it will go to 'complete'.
        # If 'complete' is the next step, it will render_wizard(@organization) or redirect to it.
        # Or, if we want to explicitly go to the 'complete' step view:
        return redirect_to wizard_path(:complete)
      else
        render_wizard # Re-renders :organization_details with errors
        return # Important to prevent double render/redirect
      end
    end
    # If the step doesn't have specific update logic or doesn't save anything,
    # wicked will just try to render the next step.
    # If no specific action taken, ensure we render or redirect.
    # For :welcome, an update isn't typical, it would just go to next step.
    # For :complete, an update isn't typical.
    # Default behavior of render_wizard might be sufficient if no specific logic.
    # However, explicit redirect or render is safer.
    if step == :welcome # Example: if welcome had a form that POSTs here
      redirect_to next_wizard_path and return
    end
    # Fallback if no other action taken in the case statement
    # render_wizard unless performed? # This might be too implicit
  end

  private

  def organization_params
    params.require(:organization).permit(:name) # Add other params as needed
  end

  def ensure_no_organization_for_wizard
    # If current step is not the first one and user has an org, redirect.
    # This allows re-entry to :welcome if they somehow navigate away and back.
    if current_user.organization.present? && step != steps.first && step != :complete
      redirect_to authenticated_root_path, notice: "You have already completed onboarding."
    elsif current_user.organization.present? && step == steps.first && step != :complete
       # If they have an org and are on the first step (welcome), move them past it.
       redirect_to next_wizard_path
    end
  end

  def ensure_organization_exists_for_complete
    if step == :complete && current_user.organization.nil?
      # If trying to access 'complete' step directly without an organization,
      # redirect them to the beginning of the wizard.
      redirect_to wizard_path(steps.first), alert: "Please complete the organization setup first."
    end
  end

  # Overriding default finish wizard path
  # Wicked by default redirects to root_path after the last step's update.
  # We want to show our 'complete' view.
  # However, our 'complete' is a step in the wizard, shown via #show.
  # The update for :organization_details explicitly redirects to wizard_path(:complete).
  # If :complete were the *actual* last processing step, this would be used:
  # def finish_wizard_path
  #   # This is where you'd redirect after the *final* step's successful update.
  #   # In our case, the 'complete' view is a step itself.
  #   # If we had another step like 'preferences' after 'organization_details',
  #   # and then wanted to go to a dashboard:
  #   # authenticated_root_path
  #   # For now, since 'complete' is a viewable step, this might not be strictly needed
  #   # if the last update action (organization_details) redirects to the 'complete' show action.
  #   wizard_path(:complete) # Or authenticated_root_path if 'complete' is just a final message before dashboard
  # end
end
