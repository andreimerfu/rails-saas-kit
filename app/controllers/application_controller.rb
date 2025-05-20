class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers
  include Pundit::Authorization # Include Pundit
  include ControllerLogging # Include enhanced logging

  helper ThemesHelper # Make theme helpers available to all controllers

  set_current_tenant_through_filter
  before_action :set_organization_as_tenant
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_user_onboarding_status, if: :user_signed_in?, unless: :devise_or_onboarding_controller?

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  # Helper method to check if the current user is an admin
  def current_admin
    current_user if user_signed_in? && current_user.is_admin?
  end
  helper_method :current_admin

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def check_user_onboarding_status
    # Redirect to onboarding if user is logged in but has no organization
    # and is not already in the onboarding flow.
    if current_user.organization_id.nil? && !current_user.is_admin? # Admins don't need an organization
      # Assuming your onboarding starts at 'welcome_onboarding_index_path' or similar
      # Adjust the path if your onboarding starts elsewhere (e.g., organization_onboarding_index_path)
      redirect_to onboarding_path(:welcome) # Wicked path for the first step
    end
  end

  def devise_or_onboarding_controller?
    devise_controller? || controller_name == "onboarding"
  end

  def set_organization_as_tenant
    organization_to_set = nil
    if current_user&.organization_id?
      # If user is signed in and has an organization, prioritize that.
      organization_to_set = current_user.organization
    elsif current_user&.is_admin?
      # Admins are not tied to a specific tenant for global access
      organization_to_set = nil
    else
      # For unauthenticated users or users without an org (e.g., during initial sign-up before org association)
      # try to find by domain. This is crucial for the sign-up/onboarding on a new domain.
      organization_to_set = Organization.find_by(domain: request.domain)
    end
    set_current_tenant(organization_to_set)
  end

  def configure_permitted_parameters
    added_attrs_signup = [ :name, :email, :password, :password_confirmation, :remember_me ]
    added_attrs_update = [ :name, :email, :password, :password_confirmation, :current_password, :remember_me ] # Added current_password for account_update
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs_signup
    devise_parameter_sanitizer.permit :sign_in, keys: [ :email, :password ] # Changed :login to :email
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs_update
  end
end
