# RSpec Testing Setup

This directory contains the RSpec test suite for the Payment System application.

## Running Tests

```bash
# Run all tests
docker-compose exec web bundle exec rspec

# Run a specific file
docker-compose exec web bundle exec rspec spec/models/payment_spec.rb

# Run a specific test
docker-compose exec web bundle exec rspec spec/models/payment_spec.rb:10

# Run with documentation format
docker-compose exec web bundle exec rspec --format documentation
```

## Directory Structure

```
spec/
├── rails_helper.rb          # Rails-specific test configuration
├── spec_helper.rb           # RSpec configuration
├── support/                 # Shared test configurations
│   ├── factory_bot.rb       # FactoryBot setup
│   └── database_cleaner.rb  # Database cleanup between tests
├── models/                  # Model specs
├── controllers/             # Controller specs (or requests/)
├── requests/                # Request specs (API testing)
├── features/                # Feature specs (high-level user flows)
└── system/                  # System specs (browser-based with Capybara)
```

## Test Types

### Model Specs (`spec/models/`)
Test your model logic, validations, associations, and scopes.

```ruby
# spec/models/payment_spec.rb
require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe "validations" do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe "associations" do
    it { should belong_to(:user) }
  end
end
```

### Request Specs (`spec/requests/`)
Test your API endpoints and controller actions.

```ruby
# spec/requests/payments_spec.rb
require 'rails_helper'

RSpec.describe "Payments API", type: :request do
  describe "POST /payments" do
    it "creates a new payment" do
      post "/payments", params: { payment: { amount: 100 } }
      expect(response).to have_http_status(:created)
    end
  end
end
```

### System Specs (`spec/system/`)
Test full user workflows with a browser.

```ruby
# spec/system/payment_creation_spec.rb
require 'rails_helper'

RSpec.describe "Payment Creation", type: :system do
  it "allows user to create a payment" do
    visit new_payment_path
    fill_in "Amount", with: "100.00"
    click_button "Create Payment"
    expect(page).to have_content("Payment created successfully")
  end
end
```

## Testing Tools

### FactoryBot
Create test data easily.

```ruby
# spec/factories/payments.rb
FactoryBot.define do
  factory :payment do
    amount { 100.00 }
    status { "pending" }
  end
end

# In your specs
payment = create(:payment)  # Creates and saves to database
payment = build(:payment)   # Creates but doesn't save
attrs = attributes_for(:payment)  # Returns hash of attributes
```

### Faker
Generate realistic fake data.

```ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end
end
```

### Shoulda Matchers
One-liner validation and association tests.

```ruby
# Validation matchers
it { should validate_presence_of(:email) }
it { should validate_uniqueness_of(:email) }
it { should validate_numericality_of(:amount) }

# Association matchers
it { should belong_to(:user) }
it { should have_many(:payments) }
```

### DatabaseCleaner
Automatically configured to clean database between tests.

## Best Practices

1. **One assertion per test** (when possible)
2. **Use descriptive test names** - the test name should explain what it tests
3. **Follow AAA pattern**: Arrange, Act, Assert
4. **Use factories instead of fixtures**
5. **Test behavior, not implementation**

## Example Test (Following Best Practices)

```ruby
require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe "#process" do
    context "when payment is valid" do
      it "changes status to completed" do
        # Arrange
        payment = create(:payment, status: "pending")
        
        # Act
        payment.process
        
        # Assert
        expect(payment.status).to eq("completed")
      end
    end
    
    context "when payment is invalid" do
      it "raises an error" do
        payment = create(:payment, amount: -10)
        expect { payment.process }.to raise_error(StandardError)
      end
    end
  end
end
```

## Configuration Files

- `.rspec` - RSpec command-line configuration
- `spec/rails_helper.rb` - Rails integration and gems
- `spec/spec_helper.rb` - Core RSpec configuration
- `spec/support/*.rb` - Shared configurations (automatically loaded)

## CI/CD

Tests run automatically on every pull request via GitHub Actions.
See `.github/workflows/ci.yml` for configuration.

