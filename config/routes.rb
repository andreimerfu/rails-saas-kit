Rails.application.routes.draw do
  # authenticate :current_admin do
  #   mount SolidQueueDashboard::Engine, at: "/solid-queue"
  # end

  # Mount Solid Queue Dashboard, restricted to admins
  authenticate :user, lambda { |u| u.platform_admin? } do
    mount SolidQueueDashboard::Engine, at: "/solid-queue"
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest.json" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_for :users, controllers: { registrations: "users/registrations", omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    authenticated :user do
      # Root path for authenticated users
      root "dashboard#index", as: :authenticated_root
    end

    unauthenticated do
      # Root path for unauthenticated users
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end

  # Enterprise OAuth
  post "enterprise_oauth/initiate", to: "enterprise_oauth#initiate", as: :enterprise_oauth_initiate
  get "enterprise_configurations/check_domain", to: "enterprise_oauth#check_domain"

  # Onboarding routes
  resources :onboarding, only: [ :show, :update ], controller: "onboarding" # Wicked expects show and update

  # Dashboard resource
  resource :dashboard, only: [ :show ], controller: "dashboard" do
    get :index, on: :collection # Ensure dashboard#index is available if used as root
  end

  # Organization management routes
  # Refactored to use singular resource and nested controllers
  resource :organization, only: [ :update ], controller: "organizations" do
    get :manage, on: :member # GET /organization/manage (maps to OrganizationsController#manage)
    # :member here is a bit of a misnomer for singular resources,
    # it creates /organization/manage.
    # If you prefer /manage_organization, use `get :manage` outside `resource`.

    # Nested controllers for specific organization functionalities
    scope module: :organizations do
      # POST /organization/invitations (maps to Organizations::InvitationsController#create)
      resources :invitations, only: [ :create ], as: :organization_invitations
      # GET /organization/pricing (maps to Organizations::PricingsController#show)
      resource :pricing, only: [ :show ] # Default helper: organization_pricing_path
      # DELETE /organization/members/:id (maps to Organizations::MembersController#destroy)
      resources :members, only: [ :destroy ], as: :organization_members
    end
  end
  # Old direct routes are replaced by the resource block above.
  # get "/organization/manage", to: "organizations#manage", as: :manage_organization
  # patch "/organization/manage", to: "organizations#update" # Covered by resource :organization, only: [:update]
  # post "/organization/invite", to: "organizations#invite", as: :invite_organization # Covered by nested invitations
  # get "/organization/pricing", to: "organizations#pricing", as: :organization_pricing # Covered by nested pricing

  # Route for creating a Stripe Checkout session for a subscription
  get "subscriptions/checkout_session", to: "subscriptions#new_checkout_session", as: :new_subscription_checkout_session

  # Routes for accepting and updating invitations (now under organizations namespace)
  get "/invitation/accept", to: "organizations/invitations#edit", as: :accept_invitation
  resource :invitation, only: [ :update ], controller: "organizations/invitations"

  # Custom payment routes have been removed to use stripe-rails gem features.

  resources :notifications, only: [ :index ] do
    patch :mark_as_read, on: :member
    patch :mark_all_as_read, on: :collection
  end

  # If you still need a very generic root_path for contexts outside of devise_scope's authenticated/unauthenticated,
  # and it should point to the login page, you might need one here.
  # However, the devise_scope structure above should make root_path contextually correct.
  # If `root_path` is still an issue in `_minimal_header.html.erb`, consider changing it to `unauthenticated_root_path`
  # as that partial is primarily for unauthenticated contexts.
  # For now, relying on the devise_scope to set root_path correctly.
end
