# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout "application", only: [ :edit ]
  # POST /resource
  # def create
  #   super
  # end

  protected

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    # `resource` is the newly signed-up user
    organization = Organization.find_by(domain: request.domain)

    if organization
      # Organization exists, associate user and redirect to dashboard (or wherever appropriate)
      resource.update(organization: organization)
      # Consider if a default role needs to be set here if not the first user.
      # For now, assuming role is handled or defaults correctly.
      authenticated_root_path # Or any other path for users joining an existing org
    else
      # No organization for this domain, redirect to organization onboarding
      # The current_user (resource) will create the organization in the onboarding flow.
      # We might want to set them as admin of the new org in the onboarding controller.
      onboarding_path(:welcome) # Wicked path for the first step
    end
  end

  # You might also need to override `set_flash_message_for_update` if you want custom messages
  # or to prevent Devise's default "signed up successfully" if redirecting to onboarding.

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
