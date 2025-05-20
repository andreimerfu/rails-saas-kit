# frozen_string_literal: true

# ServiceLogging concern provides enhanced logging capabilities for service objects
module ServiceLogging
  extend ActiveSupport::Concern
  include Loggable

  included do
    # Hook into dry-workflow steps to add logging
    if respond_to?(:steps)
      # Add logging to each step
      steps.each do |step|
        step_name = step.name
        original_method = instance_method(step_name)

        define_method(step_name) do |*args, **kwargs|
          log_step(step_name, *args, **kwargs) do
            original_method.bind_call(self, *args, **kwargs)
          end
        end
      end
    end
  end

  class_methods do
    # Enhanced call method with logging
    def call(*args, **kwargs, &block)
      instance = new

      # Log the service call
      instance.log_info("Starting service", {
        service: name,
        args: args.map(&:to_s),
        kwargs: kwargs.transform_values(&:to_s)
      })

      # Start timing
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Call the service
      result = instance.call(*args, **kwargs)

      # Calculate duration
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      duration = ((end_time - start_time) * 1000).round(2)

      # Log the result
      if result.success?
        instance.log_info("Service completed successfully", {
          service: name,
          duration_ms: duration,
          result_type: :success,
          result_value: result.value!.to_s
        })
      else
        instance.log_warn("Service completed with failure", {
          service: name,
          duration_ms: duration,
          result_type: :failure,
          failure_reason: result.failure.is_a?(Hash) ? result.failure[:type] : result.failure.to_s,
          failure_details: result.failure.to_s
        })
      end

      # Handle block if given
      if block_given?
        BlockHandler.new(result).handle(&block)
      else
        result
      end
    end
  end

  private

  # Log a step execution with timing
  def log_step(step_name, *args, **kwargs)
    # Log step start
    log_debug("Starting step #{step_name}", {
      step: step_name,
      args: args.map(&:to_s),
      kwargs: kwargs.transform_values(&:to_s)
    })

    # Start timing
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Execute the step
    result = yield

    # Calculate duration
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = ((end_time - start_time) * 1000).round(2)

    # Log the result
    if result.success?
      log_debug("Step #{step_name} completed successfully", {
        step: step_name,
        duration_ms: duration,
        result_type: :success
      })
    else
      log_warn("Step #{step_name} failed", {
        step: step_name,
        duration_ms: duration,
        result_type: :failure,
        failure_reason: result.failure.is_a?(Hash) ? result.failure[:type] : result.failure.to_s,
        failure_details: result.failure.to_s
      })
    end

    result
  end
end
