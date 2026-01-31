# Exchange Rate Updater

A production-ready Rails application that fetches and displays real-time exchange rates from the Czech National Bank (CNB).

## Features

- **Real-time CNB Exchange Rates** - Fetches daily exchange rates from Czech National Bank
- **RESTful JSON API** - Clean API with filtering capabilities
- **Interactive Web UI** - Simple interface with currency filtering
- **Swagger/OpenAPI Documentation** - Interactive API documentation at `/api-docs`
- **Smart Caching** - 10-minute cache to minimize API calls
- **Robust Error Handling** - Retry logic, timeout handling
- **Comprehensive Test Suite** - High code coverage with RSpec
- **Docker Support** - Containerized for easy deployment

## Tech Stack

- **Ruby** 3.4.8
- **Rails** 8.1.2 (API-focused, no database)
- **Faraday** 2.14 with retry middleware
- **RSpec** 8.0 with FactoryBot, WebMock
- **Swagger/OpenAPI** via rswag
- **Docker** with docker-compose

## Prerequisites

- Ruby 3.4.8
- Bundler 2.6.5
- Or Docker & Docker Compose

## Quick Start

### Option 1: Docker (Recommended)

```bash
# Build and run
docker-compose up

# Run tests
docker-compose run -e RAILS_ENV=test exchange-rate-updater bundle exec rspec
```

Access:
- **Web UI**: http://localhost:3000
- **API**: http://localhost:3000/api/v1/exchange_rates
- **Swagger UI**: http://localhost:3000/api-docs

### Option 2: Local Development

```bash
# Install dependencies
bundle install

# Start server
bin/rails server

# Run tests
bundle exec rspec

# Generate coverage report
bundle exec rspec
open coverage/index.html
```

## API Documentation

### Get Exchange Rates

**Endpoint:** `GET /api/v1/exchange_rates`

**Query Parameters:**
- `currencies` (optional) - Comma-separated currency codes (e.g., `USD,EUR,GBP`)

**Examples:**

```bash
# Get all exchange rates
curl http://localhost:3000/api/v1/exchange_rates

# Get specific currencies
curl http://localhost:3000/api/v1/exchange_rates?currencies=USD,EUR,GBP
```

**Response:**

```json
[
  {
    "source_currency": "USD",
    "target_currency": "CZK",
    "rate": 23.456,
    "amount": 1,
    "normalized_rate": 23.456,
    "date": "2026-01-31"
  }
]
```

### Project Structure

```
app/
├── models/
│   ├── currency.rb              # Value object for ISO 4217 codes
│   ├── exchange_rate.rb         # Exchange rate with validation
│   └── concerns/
│       └── value_object.rb      # Shared ActiveModel concern
├── services/
│   ├── cnb_exchange_rate_provider_service.rb  # Core business logic
│   └── concerns/
│       └── service_result.rb    # Result pattern
├── clients/
│   └── http/
│       ├── client.rb            # Generic HTTP client with retry
│       ├── cnb_client.rb        # CNB-specific client
│       └── result.rb            # HTTP result value object
├── controllers/
│   ├── api/
│   │   ├── base_controller.rb  # API base (ActionController::API)
│   │   └── v1/
│   │       └── exchange_rates_controller.rb  # JSON API
│   └── exchange_rates_controller.rb          # Web UI
└── views/
    └── exchange_rates/
        └── index.html.erb       # Interactive UI with filtering

spec/
├── models/                      # Model validations and behavior
├── services/                    # Service logic with mocked HTTP
├── clients/                     # HTTP client specs with WebMock
├── requests/                    # Controller integration tests
└── factories/                   # FactoryBot test data
```

## Testing

**Test Coverage:** 94.68%

**Test Suite Includes:**
- **Unit Tests** - Models, services, HTTP clients
- **Integration Tests** - API and web controllers
- **Mocking** - HTTP requests mocked with WebMock
- **Factories** - Test data with FactoryBot
- **Swagger Tests** - API contract validation

```bash
# Run all tests
bundle exec rspec

# Run specific test types
bundle exec rspec spec/models
bundle exec rspec spec/services
bundle exec rspec spec/requests

# Generate coverage report
bundle exec rspec
open coverage/index.html

# Generate Swagger documentation
SWAGGER_DRY_RUN=0 rails rswag:specs:swaggerize
```

## 🔧 Key Implementation Details

### Error Handling

- **HTTP Retry Logic**: 3 attempts with exponential backoff (0.5s, 1s, 2s)
- **Timeout Handling**: 10-second timeout for HTTP requests
- **Graceful Degradation**: Invalid currency codes logged but don't break requests
- **User-Friendly Errors**: Clear error messages in API and UI

### Caching Strategy

- **Cache Duration**: 10 minutes
- **Cache Key**: `cnb_exchange_rates`
- **Implementation**: Rails.cache (MemoryStore in dev, configurable in production)
- **Rationale**: Minimize CNB API calls while maintaining fresh data

### Patterns for scalability

- **Versioned API** - Namespace-based versioning (`/api/v1`) allows backward-compatible changes and API evolution
- **Value Objects** - Immutable `Currency` and `ExchangeRate` models using `ActiveModel` without database overhead
- **Service Layer** - Business logic encapsulated in `CnbExchangeRateProviderService` with clear separation of concerns
- **Repository Pattern** - Abstract `Http::Client` base class with concrete `Http::CnbClient` implementation
- **Result Pattern** - Explicit success/failure handling via `ServiceResult::Result` (no exceptions for control flow)

## Design Decisions

1. **No Database** - Exchange rates are fetched in real-time and cached. No persistence needed.

2. **Value Objects** - `Currency` and `ExchangeRate` use `ActiveModel` instead of `ActiveRecord` for validations without database overhead.

3. **Dependency Injection** - Service accepts HTTP client as parameter, enabling easy testing with mocks.

4. **Lenient Validation** - Invalid currency codes are logged but don't break requests, providing better API stability.

5. **Result Pattern** - Services return Result objects with explicit success/failure states instead of exceptions.

6. **Caching** - 10-minute cache balances fresh data with API call minimization.

7. **Retry Logic** - Faraday retry middleware handles transient failures automatically.

## Future Improvements

- **CI/CD Pipeline** - GitHub Actions for automated build/test/lint/deploy with RuboCop and Copilot reviews
- **Custom Logger** - Custom logger with correlation IDs, performance metrics for better Monitoring/Observability
- **Redis Caching** - Shared cache across instances for production scalability
- **Circuit Breaker** - `circuit_breaker` gem to prevent cascading failures from external API outages
- **Environment Management** - `dotenv-rails` for cleaner config and secret management
- **Response Serializers** - `active_model_serializers` for versioned, JSONAPI-compliant responses

---

**Author**: Mario Zappulla  
**Date**: January 2026
