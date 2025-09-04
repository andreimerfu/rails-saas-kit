require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsKit
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks generators templates devise])
    config.autoload_paths << Rails.root.join("app", "components")
    config.autoload_paths << Rails.root.join("app", "types")

    # Disable implicit auto namespaced for dir autoload in lib subfolders
    autoloader = Rails.autoloaders.main
    %w[responders constraints components inputs validators].each do |path|
      autoloader.collapse(Rails.root.join("lib", path))
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.action_mailer.smtp_settings = {
      user_name: Settings.smtp.user_name, # This is the string literal 'apikey', which is the default username for SendGrid
      password: Settings.smtp.password,
      domain: "example.com",
      address: Settings.smtp.address,
      port: Settings.smtp.port,
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
end
