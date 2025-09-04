FactoryBot.define do
  factory :enterprise_oauth_setting do
    sequence(:name) { |n| "Enterprise #{n}" }
    sequence(:domain) { |n| "enterprise#{n}.com" }
    provider { "google_oauth2" }
    client_id { "test_client_id_#{SecureRandom.hex(8)}" }
    client_secret { "test_client_secret_#{SecureRandom.hex(16)}" }

    trait :google do
      provider { "google_oauth2" }
      hd { domain } # Google's hosted domain parameter
      scopes { "openid email profile" }
    end

    trait :microsoft do
      provider { "microsoft_entra_id" }
      tenant_id { SecureRandom.uuid }
      scopes { "openid email profile User.Read" }
    end
  end
end
