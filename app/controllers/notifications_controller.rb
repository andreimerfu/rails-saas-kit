class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.newest_first.unread
    # Or, if you want to show all notifications, including read ones:
    # @notifications = current_user.notifications.newest_first
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    respond_to do |format|
      format.turbo_stream do
        # Option 1: Remove the notification from the list
        # render turbo_stream: turbo_stream.remove(@notification)

        # Option 2: Re-render the notification (it will now appear as read)
        # and update the unread count if you have one.
        streams = [
          turbo_stream.replace(@notification,
                               partial: "notifications/notification",
                               locals: { notification: @notification }),
          # Update the navbar component
          turbo_stream.replace(dom_id(current_user, :navbar_notifications),
                               component: NavbarNotificationsComponent.new(current_user: current_user))
        ]
        render turbo_stream: streams
      end
      format.html { redirect_to notifications_path, notice: "Notification marked as read." }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.mark_as_read!
    respond_to do |format|
      format.turbo_stream do
        @notifications = current_user.notifications.newest_first.unread # Re-fetch
        streams = [
          turbo_stream.replace("notifications_list",
                               partial: "notifications/list_items",
                               locals: { notifications: @notifications }),
          # Update the navbar component
          turbo_stream.replace(dom_id(current_user, :navbar_notifications),
                               component: NavbarNotificationsComponent.new(current_user: current_user))
        ]
        render turbo_stream: streams
      end
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
    end
  end

  private

  # Helper to include ActionView::RecordIdentifier for dom_id
  # This is often included in ApplicationController. If it's already there, this isn't strictly necessary here.
  include ActionView::RecordIdentifier
end
