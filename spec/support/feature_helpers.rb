module FeatureHelpers
  # Helper method to log in as a specific user in feature specs
  # @param user [User] The user to log in as
  # @example
  #   login_as(admin_user)
  #   login_as(merchant_user)
  def login_as(user)
    visit login_path
    fill_in "Email Address", with: user.email
    click_button "Sign In"
  end
end

# Include this module in all feature specs
RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
