# frozen_string_literal: true

# Loggable concern provides enhanced logging capabilities to models and controllers
module Loggable
  extend ActiveSupport::Concern

  class_methods do
    # Class-level logger with the class name as context
    def logger
      @logger ||= SemanticLogger[self]
    end
  end

  # Instance-level logger with class name and object ID as context
  def logger
    @logger ||= SemanticLogger["#{self.class.name}##{object_id}"]
  end

  # Log a message with context about the current object
  # @param level [Symbol] The log level (:trace, :debug, :info, :warn, :error, :fatal)
  # @param message [String, nil] The message to log
  # @param payload [Hash] Additional context to include in the log
  # @yield [Hash] Block that returns a hash to merge with the payload
  # @return [Boolean] Whether the message was logged
  def log(level, message = nil, **payload)
    context = { id: try(:id) }

    # Add attributes if this is an ActiveRecord model
    if self.class.ancestors.include?(ActiveRecord::Base)
      context[:attributes] = attributes.except("created_at", "updated_at")
    end

    # Merge with provided payload
    payload = context.merge(payload)

    # Log with the instance logger
    if message.nil?
      logger.send(level, payload)
    else
      # If we have both message and payload, pass message as first argument and payload as named parameters
      logger.send(level, message, payload)
    end
  end

  # Convenience methods for different log levels
  def log_trace(message = nil, **payload)
    log(:trace, message, **payload)
  end

  def log_debug(message = nil, **payload)
    log(:debug, message, **payload)
  end

  def log_info(message = nil, **payload)
    log(:info, message, **payload)
  end

  def log_warn(message = nil, **payload)
    log(:warn, message, **payload)
  end

  def log_error(message = nil, **payload)
    log(:error, message, **payload)
  end

  def log_fatal(message = nil, **payload)
    log(:fatal, message, **payload)
  end

  # Log method execution with timing information
  # @param level [Symbol] The log level
  # @param method_name [Symbol] The method to measure
  # @param message [String, nil] Optional message to include
  # @param payload [Hash] Additional context to include
  # @return [Object] The result of the method call
  def log_method(level, method_name, message = nil, **payload)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = send(method_name)
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = ((end_time - start_time) * 1000).round(2)

    log(level, message || "Executed #{method_name}",
      method: method_name,
      duration_ms: duration,
      **payload
    )

    result
  end

  # Log an exception with context
  # @param exception [Exception] The exception to log
  # @param level [Symbol] The log level (default: :error)
  # @param message [String, nil] Optional message to include
  # @param payload [Hash] Additional context to include
  # @return [Exception] The exception that was logged
  def log_exception(exception, level = :error, message = nil, **payload)
    # Use SemanticLogger's built-in exception handling
    log_message = message || "Exception occurred: #{exception.class.name}"

    # Merge additional payload
    exception_payload = {
      exception_class: exception.class.name,
      **payload
    }

    # Log with exception as the second parameter for proper SemanticLogger handling
    logger.send(level, log_message, exception_payload.merge(exception: exception))

    exception
  end
end
