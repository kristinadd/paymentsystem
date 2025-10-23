# FactoryBot configuration for RSpec
# This file configures FactoryBot to work seamlessly with RSpec
#
# FactoryBot is used to create test data easily
# Instead of:
#   User.create(name: "John", email: "john@example.com", ...)
#
# You write:
#   create(:user)  # Uses the factory definition

RSpec.configure do |config|
  # Include FactoryBot syntax methods
  # This allows you to use:
  #   create(:user)   instead of FactoryBot.create(:user)
  #   build(:user)    instead of FactoryBot.build(:user)
  #   attributes_for(:user)  instead of FactoryBot.attributes_for(:user)
  config.include FactoryBot::Syntax::Methods
end
