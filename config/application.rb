require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BillettoApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    ENV["CLERK_SECRET_KEY"] ||= Rails.application.credentials.dig(:clerk, :secret_key)
    ENV["CLERK_PUBLISHABLE_KEY"] ||= Rails.application.credentials.dig(:clerk, :publishable_key)
    ENV["CLERK_SIGN_IN_URL"] ||= "/sign-in"
    ENV["CLERK_SIGN_UP_URL"] ||= "/sign-up"
    ENV["CLERK_AFTER_SIGN_IN_URL"] ||= "/dashboard"
    ENV["CLERK_AFTER_SIGN_UP_URL"] ||= "/onboarding"
    ENV["CLERK_FRONTEND_API"] ||= Rails.application.credentials.dig(:clerk, :frontend_api)
    config.middleware.use Clerk::Rack::Middleware
    config.autoload_paths << Rails.root.join("app/domain")
    config.eager_load_paths << Rails.root.join("app/domain")
    config.autoload_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("lib")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
