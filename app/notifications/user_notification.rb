class UserNotification < Noticed::Base
  # Add your delivery methods
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer" # Example for email
  # deliver_by :action_cable, channel: "NotificationsChannel", stream: :custom_stream_name # Example for ActionCable

  # Broadcasts to the recipient (User) for Turbo Streams
  # This will target a DOM ID like "user_1_notifications" or similar,
  # which we've set up in the NavbarNotificationsComponent's turbo_stream_from helper.
  # The `notifications_stream_key` method in NavbarNotificationsComponent generates this.
  after_deliver :broadcast_to_recipient_navbar

  # Define the parameters this notification expects
  # These will be available in your notification partials
  param :message
  param :url
  param :icon # To store an icon identifier (e.g., Heroicon name)

  # Helper method to access the message for display
  def message
    params[:message]
  end

  # Helper method to access the URL for linking
  def url
    params[:url]
  end

  # Helper method to access the icon for display
  def icon
    params[:icon]
  end

  # You can define a stream name for ActionCable if you use it
  # def custom_stream_name
  #   "notifications_for_#{recipient.id}"
  # end

  private

  def broadcast_to_recipient_navbar
    return unless recipient.present?

    # Broadcast to prepend the new notification to the dropdown list
    broadcast_prepend_later_to(
      "#{recipient.to_gid_param}:notifications", # Matches notifications_stream_key in component
      target: dom_id(recipient, :navbar_notifications_list), # The ID of the list in the dropdown
      partial: "notifications/notification",
      locals: { notification: self.to_notification, user: recipient } # Pass `self.to_notification`
    )

    # Broadcast to re-render the entire navbar component to update the unread count/indicator
    broadcast_replace_later_to(
      "#{recipient.to_gid_param}:notifications", # Matches notifications_stream_key in component
      target: dom_id(recipient, :navbar_notifications), # The ID of the main component div
      component: NavbarNotificationsComponent.new(current_user: recipient)
    )

    # Also broadcast to the main notifications page if it's open
    broadcast_prepend_later_to(
      recipient, # Default stream for the user
      :notifications, # Target for `turbo_stream_from current_user, :notifications`
      target: "notifications_list", # ID on the notifications index page
      partial: "notifications/notification",
      locals: { notification: self.to_notification, user: recipient }
    )
  end

  # Helper to generate the DOM ID for an element, useful for targeting Turbo Streams.
  # Include ActionView::RecordIdentifier to make dom_id available.
  # This is often included in ApplicationController or ApplicationRecord.
  # If not available here, you might need to include it or pass it differently.
  # For simplicity, assuming it's available or will be made available.
  # Alternatively, construct the string manually if dom_id is problematic here.
  include ActionView::RecordIdentifier
end
