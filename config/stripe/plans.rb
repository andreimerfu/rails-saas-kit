# This file contains descriptions of all your Stripe plans.
# Define your plans using the stripe-rails DSL.
# These plan IDs (e.g., :starter, :business) are local to your app.
# The `id` attribute within the plan block (e.g., plan.id = "monthly_starter")
# is what gets sent to Stripe as the plan ID.
# If you run `rake stripe:prepare`, the gem will try to create these plans on Stripe.

Stripe.plan :starter do |plan|
  plan.name        = "Starter Plan"
  # The ID that will be created in Stripe. Make it environment-specific to avoid conflicts.
  plan.amount      = 0 # Amount in cents
  plan.currency    = "usd"
  plan.interval    = "month" # 'day', 'week', 'month', or 'year'
  # plan.interval_count = 1 # Default is 1
  # plan.trial_period_days = 0 # Optional
  # plan.metadata = { my_internal_app_plan_id: "starter" } # Optional metadata
end

Stripe.plan :business do |plan|
  plan.name        = "Business Plan"
  plan.amount      = 4900 # $49.00 in cents
  plan.currency    = "usd"
  plan.interval    = "month"
  # plan.metadata = { my_internal_app_plan_id: "business" }
end

# The "Enterprise" plan is typically "Contact Us" and might not be a directly subscribable Stripe plan.
# If you want it to be a subscribable plan, define it similarly.
# For now, we'll assume it's handled differently (e.g., manual setup or a different flow).

# Stripe.plan :enterprise do |plan|
#   plan.name     = "Enterprise Plan"
#   plan.id       = "enterprise_plan_#{Rails.env.downcase}"
#   plan.amount   = 19900 # Example: $199.00
#   plan.currency = 'usd'
#   plan.interval = 'month'
# end

# After defining plans, you can run `bundle exec rake stripe:prepare`
# This will attempt to create these plans on your Stripe account if they don't exist.
