# app/services/organizations/pricing_plan_fetcher.rb
module Organizations
  class PricingPlanFetcher
    include ApplicationService # Use global namespace for ApplicationService

    # The service doesn't strictly need the organization to fetch generic plans,
    # but it's passed for potential future use (e.g., custom plans per org).
    # This is the instance `call` method required by ApplicationService.
    def call(organization:)
      # Ensure organization is present, though not strictly used in current plan fetching logic
      return Failure(type: :validation, message: "Organization must be provided.") unless organization

      plan_configurations_result = fetch_stripe_plan_configurations
      return plan_configurations_result if plan_configurations_result.failure?

      formatted_plans = format_plans(plan_configurations_result.value!)
      Success(formatted_plans)
    rescue StandardError => e
      Rails.logger.error "Organizations::PricingPlanFetcher: Error fetching plans - #{e.message}"
      Failure(type: :fetch_error, message: "Could not load pricing plans: #{e.message}")
    end

    private

    def fetch_stripe_plan_configurations
      unless defined?(Stripe::Plans) && Stripe::Plans.respond_to?(:all)
        Rails.logger.warn "stripe-rails: Stripe::Plans does not respond to .all as expected. Cannot list plans."
        return Failure(type: :stripe_config_error, message: "Stripe::Plans not configured correctly.")
      end
      Success(Stripe::Plans.all)
    end

    def format_plans(plan_configurations)
      plan_configurations.map do |config_obj|
        actual_stripe_plan_id = config_obj.id
        original_symbol_candidate = actual_stripe_plan_id.to_s.chomp("_#{Rails.env.downcase}").to_sym

        plan_name = config_obj.name
        plan_amount = config_obj.amount
        plan_currency = config_obj.currency
        plan_interval = config_obj.interval
        plan_metadata = config_obj.metadata || {}

        is_contact_us_plan = plan_metadata[:contact_us] == "true" || plan_amount.nil?

        next if !is_contact_us_plan && actual_stripe_plan_id.blank?

        {
          id: original_symbol_candidate,
          stripe_plan_id: actual_stripe_plan_id,
          name: plan_name,
          description: plan_metadata[:description] || "Default plan description.",
          price_id: actual_stripe_plan_id, # Used by subscription forms
          amount: plan_amount,
          currency: plan_currency,
          interval: plan_interval,
          features: (plan_metadata[:features]&.split(",") || (plan_metadata[:features_html] || "").split("\n").map(&:strip).reject(&:empty?) || []),
          popular: plan_metadata[:popular] == "true",
          contact_us: is_contact_us_plan,
          checkout_button_label: plan_metadata[:checkout_button_label] || "Choose #{plan_name.titleize}"
        }
      end.compact
    end
  end
end
