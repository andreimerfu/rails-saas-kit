class EnterpriseOauthController < ApplicationController
  # Skip CSRF protection for this action as it's a POST from an external form
  # or ensure that the form includes the CSRF token if not using `form_with` defaults.
  # If `form_with` is used (as in the example), Rails handles CSRF automatically.

  def initiate
    email = params[:email].to_s.strip.downcase
    unless email.present? && email.match?(URI::MailTo::EMAIL_REGEXP)
      redirect_to new_user_session_path, alert: "Please enter a valid email address."
      return
    end

    domain = email.split("@").last
    unless domain
      redirect_to new_user_session_path, alert: "Could not extract domain from email."
      return
    end

    setting = EnterpriseOauthSetting.find_by(domain: domain)

    if setting
      # Store settings in session for OmniAuth setup phase
      session[:enterprise_oauth_config] = {
        provider: setting.provider,
        client_id: setting.client_id,
        client_secret: setting.client_secret, # Note: Storing secret in session is not ideal for long-lived sessions.
        # Consider alternative ways to make this available to the strategy if needed,
        # or ensure session store is secure.
        tenant_id: setting.tenant_id,
        hd: setting.hd,
        scopes: setting.scopes
      }
      # Redirect to the dynamic OmniAuth path
      # The path helper `user_omniauth_authorize_path` expects the provider symbol.
      redirect_to user_omniauth_authorize_path(setting.provider.to_sym), allow_other_host: true
    else
      redirect_to new_user_session_path, alert: "No enterprise login configured for the domain '#{domain}'. Please use your password or contact support."
    end
  end

  def check_domain
    email = params[:email].to_s.strip.downcase
    domain = email.split("@").last

    if domain.blank?
      render json: { configured: false, error: "Invalid email format." }, status: :unprocessable_entity
      return
    end

    setting = EnterpriseOauthSetting.find_by(domain: domain)

    if setting
      render json: { configured: true, idp_name: setting.provider.titleize }
    else
      render json: { configured: false }
    end
  end
end
