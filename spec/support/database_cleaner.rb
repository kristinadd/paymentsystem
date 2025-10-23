# DatabaseCleaner configuration for RSpec
# This ensures each test starts with a clean database state
#
# Why this matters:
# Without cleanup, tests can "pollute" each other:
#   Test 1: Creates a user
#   Test 2: Expects 0 users but finds 1 from Test 1!
#
# DatabaseCleaner prevents this by cleaning the database between tests

RSpec.configure do |config|
  # Before the entire test suite runs
  config.before(:suite) do
    # Use transaction strategy (fastest for PostgreSQL)
    # Each test runs in a transaction that gets rolled back
    DatabaseCleaner.strategy = :transaction

    # Clean the database thoroughly before starting
    DatabaseCleaner.clean_with(:truncation)
  end

  # Before each test
  config.before(:each) do
    # Start DatabaseCleaner
    DatabaseCleaner.start
  end

  # After each test
  config.after(:each) do
    # Clean up (rollback transaction)
    DatabaseCleaner.clean
  end
end
