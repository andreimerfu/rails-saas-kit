# Devise test helpers for feature specs
module DeviseFeatureHelpers
  def sign_out(user = nil)
    logout(:user)
  end
end

RSpec.configure do |config|
  config.include DeviseFeatureHelpers, type: :feature
end