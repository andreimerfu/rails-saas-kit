# Configure SemanticLogger for different environments
require "semantic_logger"

# Set application name for all logs
SemanticLogger.application = Rails.application.class.module_parent_name

# Set default log level
SemanticLogger.default_level = Rails.configuration.log_level || :info

# Configure appenders based on environment
if Rails.env.development? || Rails.env.test?
  # Development/Test: Colorful console output with emojis
  # Create a custom formatter class to add emojis
  class EmojiColorFormatter < SemanticLogger::Formatters::Color
    # Override level_color method to add emojis
    def level_color
      color = case level
      when :trace
                BOLD + BLUE
      when :debug
                GREEN
      when :info
                BOLD + CYAN
      when :warn
                BOLD + YELLOW
      when :error
                BOLD + RED
      when :fatal
                BOLD + WHITE + ON_RED
      else
                BOLD + RED
      end

      emoji = case level
      when :trace
                "🔍 "
      when :debug
                "🐞 "
      when :info
                "ℹ️  "
      when :warn
                "⚠️  "
      when :error
                "❌ "
      when :fatal
                "💀 "
      else
                "❓ "
      end

      "#{color}#{emoji}#{level}#{CLEAR}"
    end
  end

  SemanticLogger.add_appender(
    io: STDOUT,
    formatter: EmojiColorFormatter.new,
    level: :debug
  )

  # Enable amazing_print for better object inspection in development
  require "amazing_print"
  AmazingPrint.defaults = {
    indent: 2,
    index: false,
    sort_keys: true,
    color: {
      args: :pale,
      array: :white,
      bigdecimal: :blue,
      class: :yellow,
      date: :greenish,
      falseclass: :red,
      integer: :blue,
      float: :blue,
      hash: :pale,
      keyword: :cyan,
      method: :purpleish,
      nilclass: :red,
      rational: :blue,
      string: :green,
      struct: :pale,
      symbol: :cyanish,
      time: :greenish,
      trueclass: :green,
      variable: :cyanish
    }
  }

  # Patch Rails.logger.debug to use amazing_print for objects
  module ActionController
    class Base
      def self.log_awesome(object)
        Rails.logger.debug { object.ai }
      end
    end
  end

else
  # Production: JSON format for structured logging
  SemanticLogger.add_appender(
    io: STDOUT,
    formatter: :json
  )

  # Configure JSON format to include request_id and other context
  module SemanticLogger
    module Formatters
      class Json
        # Add custom fields to the JSON output
        alias_method :original_call, :call
        def call(log, logger)
          # Get the original JSON
          json = original_call(log, logger)
          hash = JSON.parse(json)

          # Add request_id if available
          if Thread.current[:request_id]
            hash[:request_id] = Thread.current[:request_id]
          end

          # Add current user id if available
          if Thread.current[:current_user_id]
            hash[:user_id] = Thread.current[:current_user_id]
          end

          # Add organization id if available
          if Thread.current[:organization_id]
            hash[:organization_id] = Thread.current[:organization_id]
          end

          JSON.generate(hash)
        end
      end
    end
  end
end

# Replace Rails logger
Rails.logger = SemanticLogger[Rails]

# Replace Active Record logger
ActiveRecord::Base.logger = SemanticLogger[ActiveRecord]

# Replace Action Controller logger
ActionController::Base.logger = SemanticLogger[ActionController]

# Replace Action View logger
ActionView::Base.logger = SemanticLogger[ActionView]

# Replace Action Mailer logger
ActionMailer::Base.logger = SemanticLogger[ActionMailer]

# Replace Active Job logger
ActiveJob::Base.logger = SemanticLogger[ActiveJob]

# Configure log tags to be added to all logs
Rails.application.configure do
  config.log_tags = [ :request_id ]
end

# Create a named middleware class instead of an anonymous one
class RequestContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Store request_id in thread local
    request_id = env["action_dispatch.request_id"]
    Thread.current[:request_id] = request_id if request_id

    # Call the next middleware
    @app.call(env)
  ensure
    # Clear thread locals
    Thread.current[:request_id] = nil
  end
end

# Add the middleware to the stack
Rails.application.config.middleware.use RequestContextMiddleware
