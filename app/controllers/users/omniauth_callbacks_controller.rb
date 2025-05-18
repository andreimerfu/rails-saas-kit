# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Generic handler for enterprise OAuth providers
  def google_oauth2
    handle_omniauth("Google")
  end

  def microsoft_entra_id
    handle_omniauth("Microsoft Entra ID")
  end

  # Standard GitHub OmniAuth (if still needed, otherwise can be removed or adapted)
  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    # Clear enterprise config from session on failure as well
    session.delete(:enterprise_oauth_config) if session[:enterprise_oauth_config]
    flash[:alert] = "Authentication failed: #{params[:error_description] || params[:error_reason] || 'Unknown error'}"
    redirect_to new_user_session_path
  end

  private

  def handle_omniauth(kind)
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      # Clear enterprise config from session after successful authentication
      session.delete(:enterprise_oauth_config) if session[:enterprise_oauth_config]

      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      # Clear enterprise config from session if user creation/finding failed
      session.delete(:enterprise_oauth_config) if session[:enterprise_oauth_config]

      # Preserve OmniAuth data for registration form, if applicable
      # This depends on how you want to handle new user registration from enterprise OAuth
      # For now, we'll store the relevant parts if the user is new.
      if auth
        session["devise.#{auth.provider}_data"] = auth.except(:extra)
      end

      alert_message = @user.errors.full_messages.join("\n").presence || "Could not sign you in with #{kind}."
      redirect_to new_user_registration_url, alert: alert_message
    end
  rescue StandardError => e
    # Clear enterprise config from session on any unexpected error
    session.delete(:enterprise_oauth_config) if session[:enterprise_oauth_config]
    Rails.logger.error "OmniAuth Error for #{kind}: #{e.message}\n#{e.backtrace.join("\n")}"
    flash[:alert] = "An unexpected error occurred during authentication with #{kind}. Please try again."
    redirect_to new_user_session_path
  end
end
