# app/services/application_service.rb
module ApplicationService
  extend ActiveSupport::Concern

  included do
    include Dry::Workflow
    include Dry::Monads[:result, :do]
    # include ServiceLogging # If you have a ServiceLogging concern, include it here

    # Add class method to handle blocks
    def self.call(*args, **kwargs, &block)
      instance = new
      payload = nil

      if !kwargs.empty?
        # Keyword arguments are present.
        payload = kwargs.dup # Start with kwargs as the base of the payload.
        if args.any?
          if args.length == 1 && args.first.is_a?(Hash)
            # A single positional hash argument is also present; merge it.
            # Keywords provided directly in the call will take precedence over keys in the hash.
            payload = args.first.merge(payload)
          elsif args.any? # More than one positional arg, or one that isn't a hash.
            raise ArgumentError, "Cannot reliably combine positional arguments with keyword arguments unless the single positional argument is a hash to be merged."
          end
        end
      elsif args.length == 1
        # No keyword arguments, and only one positional argument. This is the payload.
        payload = args.first
      elsif args.empty? && kwargs.empty?
        # No arguments and no keyword arguments. Pass an empty hash as payload.
        payload = {}
      else # Multiple positional arguments and no keyword arguments.
        # This is generally not expected if steps are designed for hash/keyword inputs.
        raise ArgumentError, "Service call with multiple positional arguments is not directly supported when steps expect a hash or keyword arguments. Please pass a single hash or use keyword arguments."
      end

      # Now, 'payload' is the consolidated input for the Dry::Workflow instance's call method.
      result = instance.call(payload)

      if block_given?
        BlockHandler.new(result).handle(&block)
      else
        result
      end
    end
  end

  # Block handler class
  class BlockHandler
    def initialize(result)
      @result = result
    end

    def handle(&block_config)
      # The block_config itself is the block passed from the controller.
      # We yield `self` to this block, allowing the controller to define `on.success`, `on.failure`.
      # e.g., Contacts::Create.call(params) do |on|
      #         on.success { ... }
      #         on.failure(:validate) { ... }
      #       end
      # Here, `yield self` calls the block passed to `handle` (which is the controller's block)
      # and `self` (the BlockHandler instance) becomes the `on` object in the controller.

      @success_handler = nil
      @failure_handlers = {}
      @generic_failure_handler = nil

      # Configure handlers by executing the controller's block
      block_config.call(self)

      case @result
      when Dry::Monads::Success
        @success_handler&.call(@result.value!)
      when Dry::Monads::Failure
        failure_payload = @result.failure
        handled = false

        # Check if the failure payload is a hash and has a type for specific handlers
        if failure_payload.is_a?(Hash) && failure_payload.key?(:type)
          type = failure_payload[:type]
          if @failure_handlers[type]
            @failure_handlers[type].call(failure_payload)
            handled = true
          end
        end

        # If not handled by a specific type handler, call the generic handler
        unless handled
          @generic_failure_handler&.call(failure_payload)
        end
      end
      @result # Always return the original result
    end

    def success(&block)
      @success_handler = block
    end

    def failure(type = nil, &block)
      if type.nil?
        @generic_failure_handler = block
      else
        @failure_handlers[type] = block
      end
    end
  end
end
