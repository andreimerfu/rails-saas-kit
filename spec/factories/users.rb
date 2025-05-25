FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    name { Faker::Name.name }
    confirmed_at { Time.current } # Assuming users are confirmed by default for tests

    trait :owner do
      role { :owner }
      association :organization # Assumes an organization factory exists
    end

    trait :admin do
      role { :admin }
      association :organization
    end

    trait :member do
      role { :member }
      association :organization
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    # Trait for user invited but not yet accepted
    trait :invited do
      invitation_sent_at { Time.current }
      invitation_accepted_at { nil }
      invitation_token { Devise.friendly_token }
      association :invited_by, factory: :user # Assumes invited_by is a user
      association :organization # Invited to this organization

      # Store the raw token for testing
      transient do
        raw_invitation_token { nil }
      end

      after(:build) do |user, evaluator|
        if evaluator.raw_invitation_token.nil?
          raw_token = Devise.friendly_token
          user.invitation_token = Devise.token_generator.digest(User, :invitation_token, raw_token)
          user.instance_variable_set(:@raw_invitation_token, raw_token)
        end
      end

      after(:create) do |user, evaluator|
        # Make raw token accessible for tests
        user.define_singleton_method(:raw_invitation_token) do
          @raw_invitation_token
        end
      end
    end

    # If you have a `profile` association or similar, you can add it here:
    # after(:create) do |user, evaluator|
    #   create(:profile, user: user) if evaluator.create_profile
    # end
    # transient do
    #   create_profile { true } # Default to true, set to false if you don't want a profile
    # end
  end
end
