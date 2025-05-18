class SidebarComponent < ViewComponent::Base
  include IconsHelper

  def initialize(current_user: nil)
    @current_user = current_user
  end

  def user_initial
    return "?" unless @current_user&.name.present?
    @current_user.name.split.first[0].upcase
  end

  private

  def active_link?(path)
    current_page?(path)
  end

  def navigation_items
    {
      main: [
        { icon: :home, label: "Dashboard", path: dashboard_path },
        { icon: :users, label: "Team", path: "#" },
        { icon: :folder, label: "Projects", path: "#" }
      ],
      workspace: [
        { icon: :calendar, label: "Calendar", path: "#" },
        { icon: :chart_bar, label: "Analytics", path: "#" },
        { icon: :document_text, label: "Documents", path: "#" }
      ]
    }
  end
end
