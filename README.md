# Marketplace Integration Implementation Guide

## Overview

This implementation handles integration with two different marketplaces:

- Marketplace A: Single-step listing creation
- Marketplace B: Two-step process with potential failures

## Technical Stack

- Ruby on Rails
- Faraday for HTTP client
- RSpec for testing
- WebMock for HTTP stubbing in tests

## Core Components

### Directory Structure

```
app/
├── services/
│   ├── concerns/
│   │   ├── loggable.rb
│   │   └── retryable.rb
│   ├── marketplaces/
│   │   ├── base_marketplace.rb
│   │   ├── marketplace_a.rb
│   │   └── marketplace_b.rb
│   └── result.rb
spec/
├── services/
│   └── marketplaces/
│       ├── marketplace_a_spec.rb
│       └── marketplace_b_spec.rb
└── support/
    └── webmock_helpers.rb
```

### Core Classes and Modules

#### Result Class

Provides a consistent interface for operation results:

```ruby
class Result
  attr_reader :success, :data, :error, :context

  def initialize(success:, data: {}, error: nil, context: {})
    @success = success
    @data = data
    @error = error
    @context = context
  end

  def success?
    @success
  end

  def failure?
    !success?
  end
end
```

#### Retryable Module

Handles retry logic with configurable parameters:

```ruby
module Retryable
  def with_retry(options = {})
    attempt = 1
    max_attempts = options.fetch(:max_attempts, 3)
    delay = options.fetch(:delay, 2)

    begin
      yield
    rescue => e
      if attempt < max_attempts
        sleep(delay)
        attempt += 1
        retry
      else
        raise RetryError, "Max retries exceeded: #{e.message}"
      end
    end
  end
end
```

## Implementation Details

### Base Marketplace

```ruby
module Marketplaces
  class BaseMarketplace
    include Loggable
    include Retryable

    RETRY_OPTIONS = {
      max_attempts: 3,
      delay: 2
    }

    def initialize
      @connection = Faraday.new do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    protected

    def make_request(method, url, options = {})
      with_retry(RETRY_OPTIONS) do
        @connection.send(method) do |req|
          req.url url
          req.headers.merge!(options[:headers] || {})
          req.body = options[:body] if options[:body]
        end
      end
    end
  end
end
```

## Key Design Decisions

### 1. HTTP Client Choice

- **Decision**: Used Faraday over HTTParty
- **Rationale**:
  - Better middleware support
  - More flexible request/response handling
  - Easier testing
  - Better error handling capabilities

### 2. Result Object Pattern

- **Decision**: Custom Result class instead of raising exceptions
- **Benefits**:
  - Consistent error handling
  - Rich context for errors
  - Better partial success handling
  - Clearer success/failure states

### 3. Retry Mechanism

- **Decision**: Separate Retryable module with configurable options
- **Benefits**:
  - Reusable retry logic
  - Configurable per marketplace
  - Clear separation of concerns
  - Easy to modify retry behavior

### 4. Base Marketplace Class

- **Decision**: Abstract base class with common functionality
- **Benefits**:
  - DRY code across marketplaces
  - Consistent interface
  - Shared configuration
  - Easy to add new marketplaces

## Error Handling Strategy

### Types of Errors Handled:

1. Network errors
2. API failures
3. Timeout issues
4. Partial completion states

### Error Recovery:

- Automatic retries for transient failures
- Context preservation for partial completions
- Recovery mechanisms for failed publishes

## Testing Approach

### Test Coverage:

1. Happy path scenarios
2. Temporary failures with recovery
3. Permanent failures
4. Partial completions
5. Edge cases

### Example Test Setup:

```ruby
RSpec.describe Marketplaces::MarketplaceA do
  let(:marketplace) { described_class.new }

  context 'when request fails temporarily' do
    before do
      @call_count = 0
      stub_request(:post, "http://localhost:3001/api/products")
        .to_return do
          @call_count += 1
          if @call_count < 2
            { status: 500 }
          else
            {
              status: 201,
              body: { id: "12345", status: "success" }.to_json
            }
          end
        end
    end

    it 'retries and succeeds' do
      result = marketplace.create_listing(params)
      expect(result.success?).to be true
      expect(@call_count).to eq(2)
    end
  end
end
```

## Logging Strategy

### Log Levels:

- INFO: Normal operations
- ERROR: Failed operations
- DEBUG: Detailed operation tracking

### Log Format:

```
[TIMESTAMP] [LEVEL] [SERVICE] Message {context}
```

## Trade-offs and Considerations

### 1. Synchronous vs Asynchronous

- **Choice**: Synchronous implementation
- **Trade-off**: Simpler code vs potential timeout issues
- **Mitigation**: Configurable timeouts and retry logic

### 2. Error Handling Complexity

- **Choice**: Rich error context
- **Trade-off**: More complex error handling vs better debugging
- **Benefit**: Better visibility into failures

### 3. Retry Strategy

- **Choice**: Fixed retry with delay
- **Trade-off**: Simplicity vs flexibility
- **Alternative**: Could implement exponential backoff

## Future Improvements

1. Implement async processing for long-running operations
2. Add circuit breaker pattern
3. Implement exponential backoff for retries
4. Add metrics collection
5. Implement rate limiting

## Setup Instructions

1. Add required gems to Gemfile:

```ruby
gem 'faraday'

group :test do
  gem 'rspec-rails'
  gem 'webmock'
end
```

2. Install dependencies:

```bash
bundle install
```

3. Run tests:

```bash
rspec spec/services/marketplaces
```

## Usage Example

```ruby
# Create listing on Marketplace A
marketplace_a = Marketplaces::MarketplaceA.new
result = marketplace_a.create_listing(
  title: "Product Name",
  price_cents: 1999,
  seller_sku: "ABC123"
)

if result.success?
  puts "Created listing: #{result.data[:marketplace_id]}"
else
  puts "Failed: #{result.error}"
end
```
