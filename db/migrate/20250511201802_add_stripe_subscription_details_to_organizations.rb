class AddStripeSubscriptionDetailsToOrganizations < ActiveRecord::Migration[8.0]
  def change
    # Add a jsonb column to store various subscription details from Stripe.
    # This gives flexibility if the structure of subscription data changes
    # or if different plans have different subscription-related attributes.
    add_column :organizations, :stripe_subscription_details, :jsonb, null: false, default: {}

    # Add an index on stripe_customer_id if it's frequently queried and not already indexed.
    # The migration 20250513090100_add_stripe_fields_to_organizations.rb already adds stripe_customer_id.
    # We can add an index here if it wasn't added before or if we want to ensure it exists.
    # add_index :organizations, :stripe_customer_id, unique: true # A customer ID should be unique per organization

    # You might also want to index specific keys within the jsonb field if you query them often,
    # though this depends on your database (PostgreSQL supports GIN indexes for jsonb).
    # Example for PostgreSQL:
    # add_index :organizations, "(stripe_subscription_details->>'stripe_subscription_id')", name: 'index_organizations_on_stripe_subscription_id_in_details', unique: true
    # add_index :organizations, "(stripe_subscription_details->>'status')", name: 'index_organizations_on_status_in_details'
  end
end
