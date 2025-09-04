class Organization < ApplicationRecord
  # Include Stripe::Callbacks to handle webhook events directly in the model
  include Stripe::Callbacks if defined?(Stripe::Callbacks)

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :domain, uniqueness: true, allow_nil: true

  has_many :users, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_one :enterprise_oauth_setting, foreign_key: :domain, primary_key: :domain

  # Check if organization has enterprise SSO configured
  def enterprise_login_configured?
    enterprise_oauth_setting.present?
  end

  # --- Helper methods to access data from `stripe_subscription_details` jsonb field ---

  def active_stripe_subscription_id
    stripe_subscription_details&.dig("stripe_subscription_id")
  end

  def current_stripe_plan_id
    stripe_subscription_details&.dig("current_plan_id")
  end

  def stripe_subscription_status
    stripe_subscription_details&.dig("status")
  end

  def active_subscription?
    status = stripe_subscription_status
    [ "active", "trialing" ].include?(status)
  end

  def subscribed_to?(stripe_plan_id_to_check = nil)
    return false unless active_subscription?
    current_plan = current_stripe_plan_id
    return false unless current_plan.present?
    stripe_plan_id_to_check ? current_plan == stripe_plan_id_to_check : true
  end

  def current_plan_display_name
    if active_subscription? && current_stripe_plan_id.present?
      plan_key_suffix = "_#{Rails.env.downcase}"
      plan_key_base = current_stripe_plan_id.chomp(plan_key_suffix)
      plan_key = plan_key_base.to_sym
      plan_config = Stripe::Plans[plan_key] if defined?(Stripe::Plans) && Stripe::Plans.defined?(plan_key)
      return plan_config.name if plan_config&.name
      return current_stripe_plan_id
    end
    "Not Subscribed"
  end

  before_validation :generate_slug, if: :name_changed?

  # --- Stripe Webhook Callbacks ---

  after_checkout_session_completed! do |checkout_session, event|
    organization = Organization.find_by(id: checkout_session.metadata&.organization_id)
    unless organization
      Rails.logger.error "Stripe Webhook (checkout.session.completed): Organization not found with ID #{checkout_session.metadata&.organization_id}"
      return
    end

    stripe_customer_id = checkout_session.customer
    stripe_subscription_id = checkout_session.subscription

    organization.update_column(:stripe_customer_id, stripe_customer_id) if organization.stripe_customer_id.blank? && stripe_customer_id.present?

    if stripe_subscription_id
      begin
        full_subscription = Stripe::Subscription.retrieve(id: stripe_subscription_id, expand: [ "items.data.price" ])
        organization.update_subscription_details(full_subscription)
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe Webhook (checkout.session.completed): Error retrieving subscription #{stripe_subscription_id}: #{e.message}"
      end
    else
      Rails.logger.warn "Stripe Webhook (checkout.session.completed): Subscription ID not found in checkout session for org #{organization.id}."
    end
  end

  after_customer_subscription_created! do |subscription_from_event, event|
    begin
      stripe_customer_id = subscription_from_event.customer
      organization = Organization.find_by(stripe_customer_id: stripe_customer_id)

      unless organization
        Rails.logger.error "Stripe Webhook (customer.subscription.created): Organization not found for Stripe Customer ID #{stripe_customer_id}"
        return
      end

      full_subscription = Stripe::Subscription.retrieve(id: subscription_from_event.id, expand: [ "items.data.price" ])
      organization.update_subscription_details(full_subscription)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Webhook (customer.subscription.created): Error processing subscription #{subscription_from_event.id} for customer #{stripe_customer_id}: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Stripe Webhook (customer.subscription.created): Organization not found for Stripe Customer ID #{stripe_customer_id} (during processing)."
    end
  end

  after_customer_subscription_updated! do |subscription_from_event, event|
    begin
      stripe_customer_id = subscription_from_event.customer
      organization = Organization.find_by(stripe_customer_id: stripe_customer_id)

      unless organization
        Rails.logger.error "Stripe Webhook (customer.subscription.updated): Organization not found for Stripe Customer ID #{stripe_customer_id}"
        return
      end

      full_subscription = Stripe::Subscription.retrieve(id: subscription_from_event.id, expand: [ "items.data.price" ])
      organization.update_subscription_details(full_subscription)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Webhook (customer.subscription.updated): Error processing subscription #{subscription_from_event.id} for customer #{stripe_customer_id}: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Stripe Webhook (customer.subscription.updated): Organization not found for Stripe Customer ID #{stripe_customer_id} (during processing)."
    end
  end

  after_customer_subscription_deleted! do |subscription_from_event, event|
    organization = Organization.find_by_stripe_customer_id(subscription_from_event.customer)
    if organization
      current_details = organization.stripe_subscription_details || {}
      if current_details["stripe_subscription_id"] == subscription_from_event.id
        canceled_details = {
          stripe_subscription_id: subscription_from_event.id,
          status: subscription_from_event.status,
          current_plan_id: current_details["current_plan_id"],
          current_period_start: current_details["current_period_start"],
          current_period_end: subscription_from_event["current_period_end"] ? Time.at(subscription_from_event["current_period_end"]).to_datetime : nil,
          canceled_at: subscription_from_event["canceled_at"] ? Time.at(subscription_from_event["canceled_at"]).to_datetime : Time.current,
          ended_at: subscription_from_event["ended_at"] ? Time.at(subscription_from_event["ended_at"]).to_datetime : nil
        }
        organization.update!(stripe_subscription_details: canceled_details)
        Rails.logger.info "Stripe Webhook: Subscription #{subscription_from_event.id} marked as #{subscription_from_event.status} for Organization #{organization.id}."
      end
    else
      Rails.logger.warn "Stripe Webhook (customer.subscription.deleted): Organization not found for customer #{subscription_from_event.customer}."
    end
  end

  def update_subscription_details(stripe_sub_object)
    Rails.logger.info "Stripe Webhook: Processing update_subscription_details for object ID: #{stripe_sub_object&.id}, Class: #{stripe_sub_object&.class}"

    unless stripe_sub_object.is_a?(Stripe::Subscription) && stripe_sub_object.id.present?
      Rails.logger.error "Stripe Webhook: Invalid or incomplete Stripe::Subscription object received."
      return
    end

    self.stripe_subscription_details = {
      stripe_subscription_id: stripe_sub_object.id, # Direct accessor usually works for id
      status: stripe_sub_object.status,           # Direct accessor usually works for status
      current_plan_id: stripe_sub_object.items&.data&.first&.price&.id,
      # Use hash-style access for timestamps and other fields if direct methods fail, based on provided JSON
      current_period_start: stripe_sub_object["current_period_start"] ? Time.at(stripe_sub_object["current_period_start"]).to_datetime : nil,
      current_period_end: stripe_sub_object["current_period_end"] ? Time.at(stripe_sub_object["current_period_end"]).to_datetime : nil,
      trial_start: stripe_sub_object["trial_start"] ? Time.at(stripe_sub_object["trial_start"]).to_datetime : nil,
      trial_end: stripe_sub_object["trial_end"] ? Time.at(stripe_sub_object["trial_end"]).to_datetime : nil,
      cancel_at_period_end: stripe_sub_object["cancel_at_period_end"], # Boolean
      ended_at: stripe_sub_object["ended_at"] ? Time.at(stripe_sub_object["ended_at"]).to_datetime : nil,
      created: stripe_sub_object["created"] ? Time.at(stripe_sub_object["created"]).to_datetime : nil,
      billing_cycle_anchor: stripe_sub_object["billing_cycle_anchor"] ? Time.at(stripe_sub_object["billing_cycle_anchor"]).to_datetime : nil,
      quantity: stripe_sub_object["quantity"] # Assuming quantity is a top-level attribute in the JSON
    }
    # stripe_sub_object.customer is the Stripe Customer ID
    self.stripe_customer_id = stripe_sub_object.customer if self.stripe_customer_id.blank? && stripe_sub_object.customer.present?

    save!
    Rails.logger.info "Stripe Webhook: Updated subscription details for Organization #{id} with Stripe Subscription #{stripe_sub_object.id} (Status: #{stripe_sub_object.status})."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Stripe Webhook: Failed to save subscription details for Organization #{id}. Errors: #{e.record.errors.full_messages.to_sentence}"
  rescue StandardError => e
    Rails.logger.error "Stripe Webhook: Unexpected error updating subscription details for Organization #{id} (Sub ID: #{stripe_sub_object&.id}): #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
