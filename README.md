# Payment System

A Ruby on Rails payment processing system with transaction management, merchant administration, and role-based access control.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [API Usage](#api-usage)
- [Transaction Logic](#transaction-logic)
- [Architecture](#architecture)
- [Testing](#testing)

---

## ✨ Features

### API
- RESTful API for transaction processing (JSON/XML support)
- Token-based authentication (API Keys)
- Four transaction types: Authorize, Charge, Refund, Reversal
- Request/response format negotiation (Strategy Pattern)
- Comprehensive error handling and validation

### Web UI
- Role-based access control (Admin/Merchant)
- Session-based authentication (email-only login)
- Merchant management (CRUD operations)
- Transaction viewing with filtering
- Responsive Bootstrap interface using Slim templates

### Transaction Management
- Single Table Inheritance (STI) for transaction types
- Transaction chain validation (Authorize → Charge → Refund/Reversal)
- Pessimistic locking for race condition prevention
- Automatic merchant balance updates
- Status tracking (approved, reversed, refunded, error)

### Data Management
- CSV import for users and merchants
- Automated transaction cleanup (Sidekiq background job)
- API key generation and management

---

## 🛠️ Tech Stack

- **Framework:** Ruby on Rails 8.1
- **Database:** PostgreSQL
- **Background Jobs:** Sidekiq
- **Testing:** RSpec, Capybara
- **Views:** Slim, Bootstrap 5
- **Containerization:** Docker, Docker Compose
- **Code Quality:** RuboCop

---

## 🚀 Getting Started

### Prerequisites
- Docker
- Docker Compose

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd paymentsystem
```

2. **Start the application**
```bash
docker-compose up -d
```

3. **Setup the database**
```bash
docker-compose exec -T web bin/rails db:create db:migrate
```

4. **Import sample data (optional)**
```bash
docker-compose exec -T web env RAILS_ENV=development bin/rails users:import\[sample_users_and_merchants.csv\]
```

5. **Generate API keys for merchants**
```bash
docker-compose exec -T web env RAILS_ENV=development bin/rails api_keys:generate
```

6. **Access the application**
- Web UI: http://localhost:3000
- API: http://localhost:3000/api/v1/transactions

---

## 📖 Usage

### Web Interface

#### Login
1. Visit http://localhost:3000
2. Enter your email address
3. Access is granted based on your role:
   - **Admin**: View and manage all merchants and transactions
   - **Merchant**: View and manage only your own merchant account and transactions

#### Managing Merchants
- **View**: Navigate to "Merchants" in the navigation bar
- **Edit**: Click "Edit" button on any merchant row
- **Delete**: Click "Delete" button (with confirmation)
- **Editable fields**: Name, Email, Description

#### Viewing Transactions
- **List**: Navigate to "Transactions" in the navigation bar
- **Details**: View transaction type, amount, status, customer info, and referenced transactions
- **Filtering**: Automatic based on your role (Admin sees all, Merchant sees only their own)

### API Usage

#### Authentication
Include your API key in the `Authorization` header:

```bash
Authorization: Bearer sk_your_api_key_here
```

#### Create Transaction (JSON)

**Authorize Transaction**
```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "data": {
      "type": "authorize",
      "merchant_id": 1,
      "amount": 100.50,
      "customer_email": "customer@example.com",
      "customer_phone": "1234567890"
    }
  }'
```

**Charge Transaction**
```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "data": {
      "type": "charge",
      "merchant_id": 1,
      "amount": 100.50,
      "referenced_transaction_id": "uuid-of-authorize-transaction",
      "customer_email": "customer@example.com",
      "customer_phone": "1234567890"
    }
  }'
```

**Refund Transaction**
```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "data": {
      "type": "refund",
      "merchant_id": 1,
      "amount": 100.50,
      "referenced_transaction_id": "uuid-of-charge-transaction",
      "customer_email": "customer@example.com"
    }
  }'
```

**Reversal Transaction**
```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "data": {
      "type": "reversal",
      "merchant_id": 1,
      "referenced_transaction_id": "uuid-of-authorize-transaction",
      "customer_email": "customer@example.com"
    }
  }'
```

#### XML Support
Use `Content-Type: application/xml` and wrap your data in XML format:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<data>
  <type>authorize</type>
  <merchant_id>1</merchant_id>
  <amount>100.50</amount>
  <customer_email>customer@example.com</customer_email>
  <customer_phone>1234567890</customer_phone>
</data>
```

---

## 🔄 Transaction Logic

### Transaction Types

```
┌─────────────────┐
│   AUTHORIZE     │  Reserve funds (does not transfer money)
│   (Root)        │
└────────┬────────┘
         │
    ┌────┴─────┐
    │          │
┌───▼──────┐ ┌─▼────────┐
│  CHARGE  │ │ REVERSAL │  Cancel authorization (releases funds)
│          │ │          │
└────┬─────┘ └──────────┘
     │
┌────▼─────┐
│  REFUND  │  Return charged funds to customer
└──────────┘
```

### Business Rules

1. **Authorize Transaction**
   - Root of transaction chain
   - Reserves funds but doesn't transfer
   - Requires: amount, customer info
   - No referenced transaction

2. **Charge Transaction**
   - Must reference an approved Authorize transaction
   - Amount must match Authorize amount exactly
   - Updates merchant's total transaction sum
   - An Authorize can only be charged once
   - Uses pessimistic locking to prevent race conditions

3. **Refund Transaction**
   - Must reference an approved Charge transaction
   - Amount must match Charge amount exactly
   - Decreases merchant's total transaction sum
   - Updates Charge status to "refunded"
   - A Charge can only be refunded once

4. **Reversal Transaction**
   - Must reference an approved Authorize transaction
   - No amount (releases the full authorization)
   - Can only reverse an Authorize that hasn't been charged
   - Updates Authorize status to "reversed"
   - Uses pessimistic locking to prevent race conditions
   - An Authorize can only be reversed once

### Status Flow

```
Transaction Created → approved (default)
                   → error (validation failed)

After Processing:
- Authorize → reversed (by Reversal)
- Charge → refunded (by Refund)
```

### Merchant Balance Updates

- **Charge (approved)**: +amount to merchant's total_transaction_sum
- **Refund (approved)**: -amount from merchant's total_transaction_sum
- **Reversal**: No balance change (funds were only reserved)

---

## 🏗️ Architecture

### Design Patterns

1. **Single Table Inheritance (STI)**
   - All transaction types inherit from `Transaction` base class
   - Shared columns, type-specific validations

2. **Strategy Pattern**
   - `Formatters::Json` and `Formatters::Xml` for request/response handling
   - Factory selects appropriate formatter based on `Content-Type`

3. **Registry Pattern**
   - `Transactions::Factory` maps transaction types to classes
   - `TransactionSerializer` delegates to model's `external_type`

4. **Service Objects**
   - `Transactions::Validator` - Parameter validation
   - `Transactions::Builder` - Parameter transformation
   - `Imports::Orchestrator` - CSV import coordination
   - `ApiKeyGenerator` - Secure key generation

5. **Factory Pattern**
   - `Formatters::Factory` - Create formatters
   - `Transactions::Factory` - Create transactions

6. **Template Method Pattern**
   - Base classes define structure, subclasses implement specifics

### Database Schema

**Key Tables:**
- `users` - Admin and Merchant users
- `merchants` - Merchant accounts (belongs to User)
- `transactions` - All transaction types (STI)
- `api_keys` - API authentication tokens

**Relationships:**
- User `has_one` Merchant
- Merchant `has_many` Transactions
- Merchant `has_many` ApiKeys
- Transaction `belongs_to` referenced_transaction (self-referential)

---

## 🧪 Testing

### Run All Tests
```bash
docker-compose exec -T web bundle exec rspec
```

### Run Specific Test Suites
```bash
# Feature/Integration tests (Capybara)
docker-compose exec -T web bundle exec rspec spec/features/

# Model tests
docker-compose exec -T web bundle exec rspec spec/models/

# Controller tests
docker-compose exec -T web bundle exec rspec spec/controllers/

# Service tests
docker-compose exec -T web bundle exec rspec spec/services/
```

### Run Specific File
```bash
docker-compose exec -T web bundle exec rspec spec/models/merchant_spec.rb
```

### Code Quality
```bash
# Run RuboCop
docker-compose exec -T web bundle exec rubocop

# Auto-fix offenses
docker-compose exec -T web bundle exec rubocop -a
```

---

### Background Jobs
# Run cleanup job manually
docker-compose exec web bin/rails runner "TransactionCleanupJob.perform_now"

