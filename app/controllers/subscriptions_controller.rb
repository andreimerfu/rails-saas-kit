class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization

  # GET /subscriptions/checkout_session?plan_id=stripe_plan_id_here
  def new_checkout_session
    plan_id = params[:plan_id]
    unless plan_id.present? && Stripe::Plans[plan_id.chomp("_#{Rails.env.downcase}").to_sym]
      flash[:alert] = "Invalid plan selected."
      redirect_to organization_pricing_path
      return
    end

    # Ensure the organization has a Stripe customer ID
    # The stripe-rails gem's Stripe::Customer concern should handle this.
    # We might need to explicitly create it if not.
    # For now, assume @organization.stripe_customer_id exists or will be created by Stripe Checkout.
    # If @organization.create_stripe_customer is a method from the gem, use it.
    # Otherwise, Stripe Checkout can create a customer if one isn't provided.

    begin
      checkout_session_params = {
        payment_method_types: [ "card" ],
        line_items: [ {
          price: plan_id, # This is the Stripe Plan ID (e.g., "business_plan_development")
          quantity: 1
        } ],
        mode: "subscription",
        success_url: organization_pricing_url(checkout: "success", session_id: "{CHECKOUT_SESSION_ID}", subscribed_plan_id: plan_id), # Redirect back to pricing page
        cancel_url: organization_pricing_url(checkout: "cancel"),
        metadata: {
          organization_id: @organization.id
          # user_id: current_user.id # Optional
        }
      }
      # If organization already has a stripe_customer_id, pass it to checkout
      if @organization.stripe_customer_id.present?
         checkout_session_params[:customer] = @organization.stripe_customer_id
      else
        # If no customer ID, Stripe Checkout will create one.
        # We can pass customer_email to prefill, and retrieve the customer ID from the session later via webhook.
        checkout_session_params[:customer_email] = current_user.email
      end


      checkout_session = Stripe::Checkout::Session.create(checkout_session_params)
      redirect_to checkout_session.url, allow_other_host: true, status: :see_other
    rescue Stripe::StripeError => e
      flash[:alert] = "Could not connect to Stripe: #{e.message}"
      Rails.logger.error "Stripe Error creating checkout session: #{e.message}"
      redirect_to organization_pricing_path
    end
  end

  private

  def set_organization
    @organization = current_user.organization
    redirect_to root_path, alert: "Organization not found." unless @organization
  end
end
