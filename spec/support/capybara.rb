require 'capybara/rails'
require 'capybara/rspec'

# Configure Capybara
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5

# Register Chrome driver for JavaScript tests
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Configure for feature specs
RSpec.configure do |config|
  config.before(:each, type: :feature) do
    # Use the default driver (rack_test) for non-JS tests
    Capybara.current_driver = Capybara.default_driver
  end

  config.before(:each, type: :feature, js: true) do
    # Use the JavaScript driver for JS tests
    Capybara.current_driver = Capybara.javascript_driver
  end

  config.after(:each, type: :feature) do
    # Reset to default driver after each test
    Capybara.use_default_driver
  end
end