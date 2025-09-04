# frozen_string_literal: true

class NavbarNotificationsComponent < ApplicationComponent
  include IconsHelper # Ensure heroicon helper is available
  include Dry::Initializer.define -> do
    option :current_user, reader: :private # Changed from param to option
    # We will reinstate the type constraint once this is confirmed working:
    # option :current_user, type: ::Types::Instance(User), reader: :private
  end

  def render?
    # Ensure current_user is a User object and present
    current_user.is_a?(User) && current_user.present?
  end

  def notifications
    return [] unless current_user.is_a?(User) # Guard clause
    @notifications ||= current_user.notifications.unread.newest_first.limit(10)
  end

  def unread_count
    return 0 unless current_user.is_a?(User) # Guard clause
    @unread_count ||= current_user.notifications.unread.count
  end

  def unread?
    # unread_count will be 0 if current_user is not a User, so this is safe
    unread_count.positive?
  end

  # This is needed for the turbo_stream_from helper in the component's view
  def notifications_stream_key
    # Ensure current_user is a User object before calling to_gid_param
    unless current_user.is_a?(User)
      Rails.logger.error "NavbarNotificationsComponent: current_user is not a User object, it's a #{current_user.class.name}. This should not happen."
      # Fallback or raise error, for now, let's return a generic key to avoid breaking, but this indicates a problem.
      return "invalid_user_stream_key"
    end
    "#{current_user.to_gid_param}:notifications"
  end
end
