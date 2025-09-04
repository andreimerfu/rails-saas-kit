class SidebarComponent < ViewComponent::Base
  include IconsHelper

  def initialize(current_user: nil)
    @current_user = current_user
  end

  def user_initial
    return "?" unless @current_user&.name.present?
    @current_user.name.split.first[0].upcase
  end

  def user_avatar_url
    # Placeholder for user avatar - can be replaced with actual user avatar logic
    return nil unless @current_user&.name.present?
    "https://ui-avatars.com/api/?name=#{@current_user.name}&background=570df8&color=fff&size=40"
  end

  private

  def active_link?(path)
    current_page?(path)
  end

  def navigation_items
    {
      main: [
        { icon: "home-modern", label: "Dashboard", path: dashboard_path, description: "Overview & insights" },
        { icon: "user-group", label: "Team", path: manage_organization_path, description: "Manage team members" },
        { icon: "folder", label: "Projects", path: "#", description: "Project management", badge: "3" }
      ],
      workspace: [
        { icon: "calendar-days", label: "Calendar", path: "#", description: "Schedule & events" },
        { icon: "presentation-chart-bar", label: "Analytics", path: "#", description: "Performance metrics" },
        { icon: "document", label: "Documents", path: "#", description: "Files & resources" },
        { icon: "cog-8-tooth", label: "Settings", path: "#", description: "Preferences & config" }
      ],
      quick_actions: [
        { icon: "plus-circle", label: "New Project", path: "#", style: "primary" },
        { icon: "user-plus", label: "Invite Member", path: "#", style: "secondary" }
      ]
    }
  end

  def organization_name
    @current_user&.organization&.name || "Your Organization"
  end

  def organization_plan
    # Placeholder for organization plan logic
    "Pro Plan"
  end
end
