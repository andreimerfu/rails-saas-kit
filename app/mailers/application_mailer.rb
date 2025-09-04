class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers

  default from: "from@example.com"
  layout "mailer"

  # Ensure default URL options are set for mailers
  def default_url_options
    if Rails.env.production?
      # Replace with your production host and protocol
      { host: "your_production_host.com", protocol: "https" }
    else
      # Default for development/test
      { host: "localhost", port: 3000 }
    end
  end
end
