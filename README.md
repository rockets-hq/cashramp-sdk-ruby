# Cashramp SDK Ruby

<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://github.com/rockets-hq/cashramp-sdk-ruby/actions/workflows/test.yml/badge.svg" /></a>
<img alt="Last Commit" src="https://badgen.net/github/last-commit/rockets-hq/cashramp-sdk-ruby" />
<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://img.shields.io/github/stars/rockets-hq/cashramp-sdk-ruby.svg"/></a>
<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://img.shields.io/npm/l/cashramp.svg"/></a>

The official Ruby SDK for [Cashramp's API](https://cashramp.co/commerce).

- [Documentation](https://docs.cashramp.co)

## Installation

### From GitHub (Recommended)

Add this line to your application's Gemfile:

```ruby
gem "cashramp_sdk_ruby", git: "https://github.com/rockets-hq/cashramp-sdk-ruby.git"
```

Then execute:

```bash
bundle install
```

### Direct Installation

If you're not using Bundler, you can install directly from GitHub:

```bash
gem install specific_install
gem specific_install https://github.com/rockets-hq/cashramp-sdk-ruby.git
```

## Quick Start

### 1. Initialize the Client

```ruby
require "cashramp"

# Initialize with your API credentials
client = Cashramp::Client.initialize(
  env: :test,  # or :live for production
  secret_key: "your_secret_key_here"
)
```

### 2. Basic Usage Examples

#### Check Available Countries

```ruby
response = client.available_countries
if response.success?
  puts "Available countries: #{response.result}"
else
  puts "Error: #{response.error}"
end
```

#### Get Market Rates

```ruby
response = client.market_rate(country_code: "NG")
if response.success?
  rates = response.result
  puts "Deposit rate: #{rates['depositRate']}"
  puts "Withdrawal rate: #{rates['withdrawalRate']}"
end
```

#### Create a Customer

```ruby
customer_data = {
  email: "customer@example.com",
  first_name: "John",
  last_name: "Doe",
  country_code: "US"
}

response = client.create_customer(customer_data)
if response.success?
  puts "Customer created: #{response.result}"
else
  puts "Error creating customer: #{response.error}"
end
```

#### Request a Ramp Quote

```ruby
quote_params = {
  customer: "customer_id",
  amount: 100.0,
  currency: "usd",
  payment_type: "deposit",
  payment_method_type: "mtn_momo_gh",
  country: "GH"
}

response = client.ramp_quote(quote_params)
if response.success?
  quote = response.result
end
```

## API Reference

### Configuration

#### Environment Variables

You can also configure the SDK using environment variables:

```ruby
# Set these in your environment or .env file
ENV["CASHRAMP_ENV"] = "test"  # or "live"
ENV["CASHRAMP_SECRET_KEY"] = "your_secret_key_here"

# Then initialize without parameters
client = Cashramp::Client.initialize
```

### Query Methods

#### `available_countries`

Fetch the countries where Cashramp services are available.

```ruby
response = client.available_countries
# Returns: Array of country objects with id, name, and code
```

#### `market_rate(country_code:)`

Get current market rates for deposits and withdrawals in a specific country.

```ruby
response = client.market_rate(country_code: "NG")
# Returns: Hash with depositRate and withdrawalRate
```

#### `payment_method_types(country:)`

Get available payment methods for a specific country.

```ruby
response = client.payment_method_types(country: "country_id")
# Returns: Array of payment method types available in the country
```

#### `rampable_assets`

Fetch all assets available for on/off-ramping.

```ruby
response = client.rampable_assets
# Returns: Array of supported cryptocurrency assets
```

#### `ramp_limits`

Get current limits for on/off-ramping operations.

```ruby
response = client.ramp_limits
# Returns: Hash with minimum and maximum limits
```

#### `payment_request(reference:)`

Fetch details of a specific payment request.

```ruby
response = client.payment_request(reference: "payment_ref")
# Returns: Payment request details
```

#### `account`

Get account information for the authenticated user.

```ruby
response = client.account
# Returns: Account details and balance information
```

#### `ramp_quote(customer:, amount:, currency:, payment_type:, payment_method_type:, country: nil)`

Request a quote for a Direct Ramp transaction.

```ruby
response = client.ramp_quote(
  customer: "customer_id",
  amount: 100.0,
  currency: "usd",
  payment_type: "deposit",
  payment_method_type: "bank_transfer_ng",
  country: "NG"
)
# Returns: Quote object with pricing and transaction details
```

#### `refresh_ramp_quote(ramp_quote_id:, amount: nil)`

Refresh an existing Ramp Quote.

```ruby
response = client.refresh_ramp_quote(ramp_quote_id: "quote_id", amount: 150.0)
# Returns: Updated quote object
```

### Mutation Methods

#### `confirm_transaction(payment_request:, transaction_hash:)`

Confirm a cryptocurrency transaction sent to Cashramp's escrow address.

```ruby
response = client.confirm_transaction(
  payment_request: "payment_request_id",
  transaction_hash: "0x..."
)
# Returns: Transaction confirmation response
```

#### `initiate_hosted_payment(amount:, currency:, country_code:, payment_type:, reference:, redirect_url:, first_name:, last_name:, email:)`

Initiate a hosted payment request

```ruby
response = client.initiate_hosted_payment(
  amount: 100.0,
  currency: "usd",
  country_code: "NG",
  payment_type: "deposit",
  reference: "unique_ref_123",
  redirect_url: "https://yourapp.com/callback",
  first_name: "Gabriel",
  last_name: "Okocha",
  email: "gabby@example.com"
)
# Returns: Payment request object with id, hostedLink, and status
```

#### `cancel_hosted_payment(payment_request_id:)`

Cancel a hosted payment request.

```ruby
response = client.cancel_hosted_payment(
  payment_request_id: "payment_request_id"
)
# Returns: Cancellation confirmation response
```

#### `create_customer(first_name:, last_name:, email:, country:)`

Create a new customer profile.

```ruby
customer = client.create_customer({
  first_name: "Chinedu",
  last_name: "Okorie",
  email: "chinedu@example.com",
  country: "country_id"
})
# Returns: Created customer object with ID
```

#### `add_payment_method(customer:, payment_method_type:, fields:)`

Add a payment method for an existing customer.

```ruby
payment_method = client.add_payment_method({
  customer: "customer_id",
  payment_method_type: "payment_method_type_id",
  fields: [
    { identifier: "", value: "" }
  ]
})
# Returns: Created payment method object
```

#### `withdraw_onchain(address:, amount_usd:, network:, metadata:)`

Withdraw your current balance as stablecoins to an on-chain wallet address.

```ruby
response = client.withdraw_onchain(
  address: "0x...",
  amount_usd: 100,
  network: "OP"
  metadata: { reference: "xyz" }
)
# Returns: Withdrawal transaction details
```

#### `initiate_ramp_quote_deposit(ramp_quote_id:, reference: nil, phone_number: nil, bank_account_number: nil)`

Initiate a deposit transaction using a ramp quote.

```ruby
response = client.initiate_ramp_quote_deposit(
  ramp_quote_id: "quote_id",
  reference: "unique_reference",
  phone_number: "+233273448978"
)
# Returns: Deposit initiation response
```

#### `mark_deposit_as_paid(payment_request_id:, receipt: nil)`

Mark a deposit as paid by the customer.

```ruby
response = client.mark_deposit_as_paid(
  payment_request_id: "payment_request_id",
  receipt: "https://example.com/receipt.jpg"
)
# Returns: Payment confirmation response
```

#### `cancel_deposit(payment_request_id:)`

Cancel an initiated deposit.

```ruby
response = client.cancel_deposit(
  payment_request_id: "payment_request_id"
)
# Returns: Cancellation confirmation response
```

#### `initiate_ramp_quote_withdrawal(ramp_quote_id:, payment_method_id:, reference: nil)`

Initiate a withdrawal transaction using a ramp quote.

```ruby
response = client.initiate_ramp_quote_withdrawal(
  ramp_quote_id: "quote_id",
  payment_method_id: "payment_method_id",
  reference: "unique_reference"
)
# Returns: Withdrawal initiation response
```

#### `mark_withdrawal_as_received(payment_request_id)`

Mark a withdrawal as received by the customer.

```ruby
response = client.mark_withdrawal_as_received(
  payment_request_id: "payment_request_id"
)
# Returns: Withdrawal confirmation response
```

## Advanced Usage

### Custom GraphQL Queries

For advanced use cases, you can send custom GraphQL queries directly:

```ruby
query = <<-GRAPHQL
  query GetAvailableCountries {
    availableCountries {
      code
      name
    }
  }
GRAPHQL

response = client.send_request(
  name: "availableCountries",
  query: query,
  variables: {}
)

if response.success?
  puts "Available countries: #{response.result}"
else
  puts "Error: #{response.error}"
end
```

### Error Handling

All SDK methods return a response object with consistent error handling:

```ruby
response = client.available_countries

if response.success?
  # Success - access the result
  countries = response.result
  puts "Found #{countries.length} countries"
else
  # Error - check the error details
  puts "Error: #{response.error}"
  # Handle the error appropriately
end
```

### Response Object Structure

```ruby
# Success response
{
  success?: true,
  result: { /* API response data */ },
  error: nil
}

# Error response
{
  success?: false,
  result: nil,
  error: "Error message or details"
}
```

## Getting API Credentials

1. Visit [Accrue Commerce](https://cashramp.co/commerce)
2. Sign up or log in to your account
3. Navigate to Developer Settings
4. Generate your API keys
5. Use the secret key in your application configuration

## Testing

The SDK supports both test and live environments:

```ruby
# Test environment (default for development)
client = Cashramp::Client.initialize(env: :test, secret_key: "test_key")

# Live environment (for production)
client = Cashramp::Client.initialize(env: :live, secret_key: "live_key")
```

## Support

- 📚 [API Documentation](https://docs.cashramp.co)
- 💬 [Support Center](mailto:cashramp@useaccrue.com)
- 🐛 [Report Issues](https://github.com/rockets-hq/cashramp-sdk-ruby/issues)

### Reporting Issues

Found a bug? Please report it on [GitHub Issues](https://github.com/rockets-hq/cashramp-sdk-ruby/issues) with:

- Ruby version
- Gem version
- Steps to reproduce
- Expected vs actual behavior

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
