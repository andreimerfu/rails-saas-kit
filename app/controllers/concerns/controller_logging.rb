# frozen_string_literal: true

# ControllerLogging concern provides enhanced logging capabilities for controllers
module ControllerLogging
  extend ActiveSupport::Concern
  include Loggable

  included do
    # Add around action to log all controller actions
    around_action :log_controller_action

    # Add after action to log response details
    after_action :log_response

    # Add rescue handlers to log exceptions
    rescue_from StandardError, with: :log_and_raise_error
  end

  private

  # Log the controller action with timing information
  def log_controller_action
    # Start timing
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Get request details
    request_details = {
      controller: params[:controller],
      action: params[:action],
      method: request.method,
      path: request.fullpath,
      format: request.format.symbol,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      params: filtered_parameters
    }

    # Add user context if available
    if respond_to?(:current_user) && current_user
      request_details[:user_id] = current_user.id
      Thread.current[:current_user_id] = current_user.id

      # Add organization context if available
      if current_user.respond_to?(:organization) && current_user.organization
        request_details[:organization_id] = current_user.organization.id
        Thread.current[:organization_id] = current_user.organization.id
      end
    end

    # Log the request
    log_info({ message: "Started #{request.method} #{request.fullpath}" }.merge(request_details))

    # Execute the action
    yield

    # Calculate duration
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = ((end_time - start_time) * 1000).round(2)

    # Log completion
    log_info({
      message: "Completed #{response.status} in #{duration}ms",
      status: response.status,
      duration_ms: duration
    })

  rescue => e
    # Calculate duration even if there was an error
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = ((end_time - start_time) * 1000).round(2)

    # Log the error with request context
    log_exception(e, :error, "Error processing #{request.method} #{request.fullpath}",
      duration_ms: duration,
      request: request_details
    )

    # Re-raise the error to be handled by Rails
    raise
  ensure
    # Clear thread locals
    Thread.current[:current_user_id] = nil
    Thread.current[:organization_id] = nil
  end

  # Log response details for non-HTML responses
  def log_response
    return if request.format.html? || response.body.blank?

    # For API responses, log a sample of the response body
    if request.format.json? || request.format.xml?
      sample = response.body.size > 1000 ? "#{response.body[0..1000]}..." : response.body
      log_debug({
        message: "Response body",
        body_sample: sample
      })
    end
  end

  # Log and re-raise errors
  def log_and_raise_error(exception)
    log_exception(exception, :error, "Unhandled exception in #{params[:controller]}##{params[:action]}")

    # Re-raise the exception for Rails to handle
    raise exception
  end

  # Filter sensitive parameters
  def filtered_parameters
    # Use Rails parameter filtering
    params.to_unsafe_h.except(
      "controller", "action", "format", "authenticity_token", "utf8", "_method"
    )
  end
end
