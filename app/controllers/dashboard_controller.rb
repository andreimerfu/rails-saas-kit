class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @organization = current_user.organization
    @dashboard_data = prepare_dashboard_data
  end

  private

  def prepare_dashboard_data
    {
      stats: {
        team_members: calculate_team_members,
        active_projects: calculate_active_projects,
        monthly_revenue: calculate_monthly_revenue,
        completion_rate: calculate_completion_rate
      },
      recent_activities: fetch_recent_activities,
      team_status: fetch_team_status,
      notifications: fetch_notifications
    }
  end

  def calculate_team_members
    # In a real app, this would query the actual user count for the organization
    @organization&.users&.count || 12
  end

  def calculate_active_projects
    # Placeholder for actual project count logic
    8
  end

  def calculate_monthly_revenue
    # Placeholder for actual revenue calculation
    24500
  end

  def calculate_completion_rate
    # Placeholder for actual completion rate calculation
    89
  end

  def fetch_recent_activities
    # In a real app, this would fetch from an activities or audit log table
    [
      {
        type: :project_completed,
        title: 'Project "Website Redesign" completed',
        description: "Completed by Sarah Chen",
        time: "2 hours ago",
        status: "completed",
        icon: "check",
        color: "success"
      },
      {
        type: :member_invited,
        title: "New team member invited",
        description: "john.doe@example.com",
        time: "4 hours ago",
        status: "pending",
        icon: "exclamation-triangle",
        color: "warning"
      },
      {
        type: :feature_deployed,
        title: "New feature deployed",
        description: "Version 2.1.0 released",
        time: "1 day ago",
        status: "released",
        icon: "rocket-launch",
        color: "info"
      }
    ]
  end

  def fetch_team_status
    # In a real app, this would fetch from user presence/status data
    [
      {
        name: "Sarah Chen",
        role: "Product Manager",
        status: "online",
        avatar_name: "Sarah+Chen"
      },
      {
        name: "John Doe",
        role: "Developer",
        status: "away",
        avatar_name: "John+Doe"
      },
      {
        name: "Maria Garcia",
        role: "Designer",
        status: "offline",
        avatar_name: "Maria+Garcia"
      }
    ]
  end

  def fetch_notifications
    # In a real app, this would fetch from a notifications table
    [
      {
        type: "info",
        title: "System Update",
        description: "Maintenance scheduled for tonight",
        icon: "bell"
      },
      {
        type: "success",
        title: "Backup Complete",
        description: "All data successfully backed up",
        icon: "check-circle"
      },
      {
        type: "warning",
        title: "Storage Warning",
        description: "85% of storage space used",
        icon: "exclamation-triangle"
      }
    ]
  end
end
