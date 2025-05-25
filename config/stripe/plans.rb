# This file contains descriptions of all your Stripe plans.
# Define your plans using the stripe-rails DSL.
# These plan IDs (e.g., :starter, :business) are local to your app.
# The `id` attribute within the plan block (e.g., plan.id = "monthly_starter")
# is what gets sent to Stripe as the plan ID.
# If you run `rake stripe:prepare`, the gem will try to create these plans on Stripe.

Stripe.plan :starter do |plan|
  plan.name        = "Starter"
  plan.amount      = 2900 # $29.00 in cents
  plan.currency    = "usd"
  plan.interval    = "month"
  plan.metadata    = {
    description: "Perfect for small teams getting started",
    features: "Up to 5 team members,10GB storage,Basic analytics,Email support,Core integrations",
    popular: "false",
    checkout_button_label: "Start Free Trial"
  }
end

Stripe.plan :professional do |plan|
  plan.name        = "Professional"
  plan.amount      = 7900 # $79.00 in cents
  plan.currency    = "usd"
  plan.interval    = "month"
  plan.metadata    = {
    description: "Advanced features for growing businesses",
    features: "Up to 25 team members,100GB storage,Advanced analytics,Priority support,All integrations,Custom workflows,API access",
    popular: "true",
    checkout_button_label: "Get Professional"
  }
end

# Enterprise plan is handled as "Contact Us" - not a direct Stripe subscription
# We'll handle this plan separately in the application logic
# Stripe.plan :enterprise do |plan|
#   plan.name        = "Enterprise"
#   plan.amount      = 99900 # Placeholder amount - actual pricing is custom
#   plan.currency    = "usd"
#   plan.interval    = "month"
#   plan.metadata    = {
#     description: "Custom solutions for large organizations",
#     features: "Unlimited team members,Unlimited storage,Enterprise analytics,24/7 phone support,Custom integrations,Advanced security,Dedicated success manager,SLA guarantee",
#     popular: "false",
#     contact_us: "true",
#     checkout_button_label: "Contact Sales"
#   }
# end

# After defining plans, you can run `bundle exec rake stripe:prepare`
# This will attempt to create these plans on your Stripe account if they don't exist.
