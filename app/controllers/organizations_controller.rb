class OrganizationsController < ApplicationController
  layout "application", only: [ :manage ]

  before_action :authenticate_user!
  before_action :authorize_organization_management

  def manage
    @organization = current_user.organization
    @members = @organization.users # Assuming 'users' is the association for members
  end

  def update
    @organization = current_user.organization
    if @organization.update(organization_params)
      redirect_to manage_organization_path, notice: "Organization name updated successfully."
    else
      render :manage, status: :unprocessable_entity
    end
  end

  def invite
    email = params[:email] # Assuming email is passed directly or nested
    organization = current_user.organization

    if email.blank?
      redirect_to manage_organization_path, alert: "Email cannot be blank."
      return
    end

    # Basic email format validation
    unless email =~ URI::MailTo::EMAIL_REGEXP
      redirect_to manage_organization_path, alert: "Invalid email format."
      return
    end

    user = User.find_by(email: email)

    if user
      if user.organization == organization
        redirect_to manage_organization_path, alert: "#{email} is already a member of this organization."
      else
        # User exists but is in a different organization
        redirect_to manage_organization_path, alert: "#{email} belongs to a different organization."
      end
    else
      # User does not exist, invite them
      invited_user = User.invite!(email: email, organization: organization)

      if invited_user.persisted?
        redirect_to manage_organization_path, notice: "Invitation sent to #{email}."
      else
        error_messages = invited_user.errors.full_messages.to_sentence
        redirect_to manage_organization_path, alert: "Failed to send invitation to #{email}: #{error_messages}"
      end
    end
  end

  def pricing
    @organization = current_user.organization
    authorize @organization # Pundit authorization

    begin
      # Fetch plans defined in config/stripe/plans.rb using stripe-rails
      # Stripe::Plans.all returns an array of Stripe::Plans::Configuration objects.
      plan_configurations = []
      if defined?(Stripe::Plans) && Stripe::Plans.respond_to?(:all)
        plan_configurations = Stripe::Plans.all
      else
        Rails.logger.warn "stripe-rails: Stripe::Plans does not respond to .all as expected. Cannot list plans."
      end

      @plans = plan_configurations.map do |config_obj|
        # For a Stripe::Plans::Configuration object:
        # - config_obj.id IS the actual Stripe Plan ID (e.g., "starter_plan_development")
        # - config_obj.name is the plan name (e.g., "Starter Plan")
        # - config_obj.amount, .currency, .interval are direct attributes.
        # - config_obj.metadata is a hash.
        # The original symbol used to define the plan (e.g., :starter) might be stored
        # as an instance variable like @id_as_symbol or might need to be inferred if not directly accessible.

        actual_stripe_plan_id = config_obj.id # This IS the ID on Stripe.com

        # Try to get the original symbol used in Stripe.plan :symbol
        # This is often stored as an instance variable like @original_id or @id_as_symbol by such DSLs.
        # If not directly available, we can infer it by removing the Rails.env suffix if present.
        original_symbol_candidate = actual_stripe_plan_id.to_s.chomp("_#{Rails.env.downcase}").to_sym
        # A more robust way would be if the gem stores this symbol on the config_obj, e.g., config_obj.key_name

        plan_name = config_obj.name
        plan_amount = config_obj.amount
        plan_currency = config_obj.currency
        plan_interval = config_obj.interval
        plan_metadata = config_obj.metadata || {}

        is_contact_us_plan = plan_metadata[:contact_us] == "true" || plan_amount.nil?

        # A plan needs an actual_stripe_plan_id to be subscribable, unless it's a "Contact Us" plan.
        next if !is_contact_us_plan && actual_stripe_plan_id.blank?

        {
          # Use the inferred original symbol for local identification if needed by view helpers,
          # or the actual_stripe_plan_id if that's what the helper expects.
          # For the `subscribe_button_for plan_id` helper, it usually expects the Stripe Plan ID.
          id: original_symbol_candidate, # Local symbolic representation
          stripe_plan_id: actual_stripe_plan_id, # Actual ID on Stripe.com
          name: plan_name,
          description: plan_metadata[:description] || "Default plan description.",
          price_id: actual_stripe_plan_id, # This is what the subscription form/button will use
          amount: plan_amount,
          currency: plan_currency,
          interval: plan_interval,
          features: (plan_metadata[:features]&.split(",") || (plan_metadata[:features_html] || "").split("\n").map(&:strip).reject(&:empty?) || []),
          popular: plan_metadata[:popular] == "true",
          contact_us: is_contact_us_plan,
          checkout_button_label: plan_metadata[:checkout_button_label] || "Choose #{plan_name.titleize}"
        }
      end.compact

      # Handle redirect parameters from Stripe Checkout
      if params[:checkout] == "success"
        # Reload the organization to get the latest subscription details updated by the webhook.
        @organization.reload
        flash.now[:notice] = "Your subscription has been updated successfully!"
        # You could make the message more specific if params[:subscribed_plan_id] is available
        # and you fetch plan details, e.g.,
        # if params[:subscribed_plan_id]
        #   plan_key = params[:subscribed_plan_id].chomp("_#{Rails.env.downcase}").to_sym
        #   plan_config = Stripe::Plans[plan_key] if defined?(Stripe::Plans) && Stripe::Plans.defined?(plan_key)
        #   flash.now[:notice] = "Successfully subscribed to the #{plan_config&.name || 'plan'}!" if plan_config
        # end
      elsif params[:checkout] == "cancel"
        flash.now[:warning] = "Your subscription process was cancelled."
      end

    rescue StandardError => e
      Rails.logger.error "Error fetching plans via stripe-rails: #{e.message}"
      @plans = []
      flash.now[:alert] = "Could not load pricing plans: #{e.message}"
    end
  end

  # Removed create_checkout_session as stripe-rails should handle subscription creation.

  private

  def organization_params
    params.require(:organization).permit(:name)
  end

  private

  def authorize_organization_management
    unless current_user&.is_owner_or_admin?
      redirect_to root_path, alert: "You are not authorized to manage organizations."
    end
  end
end
