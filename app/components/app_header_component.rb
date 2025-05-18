class AppHeaderComponent < ViewComponent::Base # Renamed from NavbarComponent
  include IconsHelper
  include ThemesHelper

  # Added breadcrumbs parameter as per strategy for page context
  def initialize(current_user: nil, organization_name: nil, breadcrumbs: [])
    @current_user = current_user
    @organization_name = organization_name
    @breadcrumbs = breadcrumbs # Store breadcrumbs
  end

  def organization_display_name
    @organization_name || @current_user&.organization&.name || "Dashboard" # Default to Dashboard if no org name
  end

  # Accessor for breadcrumbs
  attr_reader :breadcrumbs
end
