FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    domain { Faker::Internet.unique.domain_name }
    # Add other attributes for Organization as needed
    # e.g., stripe_customer_id { "cus_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
    # e.g., stripe_subscription_id { "sub_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
    # e.g., subscription_status { "active" } # or any default status

    trait :with_owner do
      after(:create) do |organization|
        create(:user, :owner, organization: organization)
      end
    end

    # Example: Trait for an organization with an active subscription
    # trait :with_active_subscription do
    #   stripe_customer_id { "cus_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
    #   stripe_subscription_id { "sub_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
    #   subscription_status { "active" }
    #   current_period_end { 1.month.from_now }
    #   plan_id { "pro_plan" } # Assuming you have plan IDs
    # end
  end
end
