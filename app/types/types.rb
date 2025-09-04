# frozen_string_literal: true

require "dry-types"

# Define your custom types module.
# This makes it available globally as ::Types
module Types
  include Dry.Types()

  # You can define more specific types here if needed, for example:
  # Email = String.constrained(format: URI::MailTo::EMAIL_REGEXP)
  # Age = Integer.constrained(gt: 18)
end
