# config/initializers/stripe.rb

# Global Stripe API key is set in environment files (e.g., config/environments/development.rb)
# by stripe-rails:
#   config.stripe.secret_key = Settings.stripe.secret_key
# This also sets Stripe.api_key.

# StripeRails gem configuration is also in environment files:
#   config.stripe.publishable_key = Settings.stripe.publishable_key

# Configure StripeEvent for webhook signing secret if stripe-rails uses it.
# This is crucial for verifying webhook authenticity.
if defined?(StripeEvent)
  StripeEvent.signing_secret = Settings.stripe.signing_secret # From config/settings.yml

  # You can subscribe to specific events here if needed,
  # though stripe-rails might handle common subscription events automatically
  # through its model concerns.
  # Example:
  # StripeEvent.subscribe 'customer.subscription.updated' do |event|
  #   # Logic to handle subscription updates
  #   # For example, find the user/organization and update their status
  #   subscription = event.data.object
  #   # ...
  # end
  #
  # StripeEvent.subscribe 'invoice.payment_succeeded' do |event|
  #   # ...
  # end
  #
  # StripeEvent.subscribe 'invoice.payment_failed' do |event|
  #   # ...
  # end
end

# Plan definitions are located in config/stripe/plans.rb
