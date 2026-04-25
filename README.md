# Cashramp SDK Ruby

<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://github.com/rockets-hq/cashramp-sdk-ruby/actions/workflows/test.yml/badge.svg" /></a>
<img alt="Last Commit" src="https://badgen.net/github/last-commit/rockets-hq/cashramp-sdk-ruby" />
<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://img.shields.io/github/stars/rockets-hq/cashramp-sdk-ruby.svg"/></a>
<a href="https://github.com/rockets-hq/cashramp-sdk-ruby/blob/main/LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-blue.svg"/></a>

The official Ruby SDK for [Cashramp's API](https://cashramp.co/commerce).

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
  - [Hosted Payments](#hosted-payments)
  - [Direct Ramp - Deposits](#direct-ramp---deposits)
  - [Direct Ramp - Withdrawals](#direct-ramp---withdrawals)
  - [Bot Agents](#bot-agents)
- [API Reference](#api-reference)
- [Custom Queries](#custom-queries)
- [Error Handling](#error-handling)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "cashramp_sdk_ruby"
```

And then run:

```bash
bundle install
```

Or install it directly with:

```bash
gem install cashramp_sdk_ruby
```

## Quick Start

```ruby
require "cashramp"

Cashramp::Client.initialize(
  env: :test, # :test for sandbox, :live for production
  secret_key: "CSHRMP-SECK_your_secret_key",
)
```

You can also configure via environment variables:

```bash
export CASHRAMP_ENV=test
export CASHRAMP_SECRET_KEY=CSHRMP-SECK_your_secret_key
```

```ruby
Cashramp::Client.initialize
```

## Usage Examples

### Hosted Payments

Hosted payments redirect users to Cashramp's hosted page to complete transactions.

```ruby
deposit = Cashramp::Client.initiate_hosted_payment(
  amount: 100,
  currency: "usd", # "usd" or "local_currency"
  country_code: "GH",
  payment_type: "deposit",
  reference: "order_123",
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  redirect_url: "https://yoursite.com/callback",
  metadata: { order_id: "order_123", user_id: "user_42" },
)

if deposit.success?
  # Redirect the user to the hosted page
  puts deposit.result["hostedLink"]
else
  puts "Error: #{deposit.error}"
end
```

### Direct Ramp - Deposits

Direct Ramp gives you full control over the payment UI. Users pay fiat and receive stablecoins.

```ruby
# Step 1: Create a customer
customer = Cashramp::Client.create_customer(
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  country: "country_global_id", # from Cashramp::Client.available_countries
)

# Step 2: Get a quote
quote = Cashramp::Client.ramp_quote(
  customer: customer.result["id"],
  amount: 100,
  currency: "usd",
  payment_type: "deposit",
  payment_method_type: "mobile_money", # from Cashramp::Client.payment_method_types
)

# Step 3: Initiate the deposit
deposit = Cashramp::Client.initiate_ramp_quote_deposit(
  ramp_quote_id: quote.result["id"],
  reference: "order_123",
  phone_number: "+233123456789", # for mobile money
)

if deposit.success?
  puts deposit.result["paymentDetails"]
  puts deposit.result["expiresAt"]
end

# Step 4: Mark as paid (after the user confirms payment)
Cashramp::Client.mark_deposit_as_paid(
  payment_request_id: deposit.result["id"],
  receipt: "https://example.com/receipt.png",
)
```

#### Receiving Stablecoins Onchain

To deliver stablecoins directly to a wallet address instead of your Cashramp Merchant Dashboard balance:

```ruby
deposit = Cashramp::Client.initiate_ramp_quote_deposit(
  ramp_quote_id: quote.result["id"],
  reference: "order_123",
  onchain_transfer_info: {
    address: "0x1234567890abcdef1234567890abcdef12345678",
    cryptocurrency: "usd_tether", # from Cashramp::Client.rampable_assets
    network: "celo", # from Cashramp::Client.rampable_assets
  },
)
```

### Direct Ramp - Withdrawals

Users receive fiat to their bank/mobile money in exchange for stablecoins.

```ruby
# Step 1: Create the customer (if not already done)
customer = Cashramp::Client.create_customer(
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  country: "country_global_id",
)

# Step 2: Add a payment method for the customer
payment_method = Cashramp::Client.add_payment_method(
  customer: customer.result["id"],
  payment_method_type: "bank_transfer",
  fields: [
    { identifier: "account_number", value: "1234567890" },
    { identifier: "bank_name",      value: "Example Bank" },
  ],
  ownership: "first_party", # optional: "first_party" or "third_party"
)

# Step 3: Get a quote
quote = Cashramp::Client.ramp_quote(
  customer: customer.result["id"],
  amount: 50,
  currency: "usd",
  payment_type: "withdrawal",
  payment_method_type: "bank_transfer",
)

# Step 4: Initiate the withdrawal
withdrawal = Cashramp::Client.initiate_ramp_quote_withdrawal(
  ramp_quote_id: quote.result["id"],
  payment_method_id: payment_method.result["id"],
  reference: "withdrawal_456",
)

# Step 5: Mark as received (after the user confirms receipt)
Cashramp::Client.mark_withdrawal_as_received(
  payment_request_id: withdrawal.result["id"],
)
```

### Bot Agents

If your secret key is bound to an Agent (rather than a merchant), the SDK can drive a bot agent end-to-end against Cashramp's bot agent GraphQL surface. Bot agent methods automatically target `/cashramp/bot/graphql` (the merchant endpoint at `/cashramp/api/graphql` is unaffected). The same `secret_key:` constructor argument is used.

```ruby
Cashramp::Client.initialize(
  env: :test,
  secret_key: "CSHRMP-SECK_your_agent_secret_key", # an APIKey whose bearer is an Agent
)

# 1. Inspect the agent profile
profile = Cashramp::Client.bot_agent_profile

# 2. Set deposit/withdrawal rates and margins
Cashramp::Client.update_bot_agent_rates(
  deposit_rate: 1500,
  withdrawal_rate: 1490,
  deposit_margin: 0.005,
)

# 3. Top up local-currency liquidity for one of your payment methods
Cashramp::Client.update_bot_agent_payment_method_liquidity(
  payment_method_id: "pm_global_id",
  amount_local: 5_000_000,
)

# 4. Page through assigned orders
orders = Cashramp::Client.bot_agent_order_history(
  page: 1,
  per_page: 20,
  filter: { status: "pending" },
)

# 5. Accept an assigned withdrawal, then mark it paid after sending fiat
assignment = orders.result["data"].first
Cashramp::Client.accept_bot_agent_withdrawal(payment_request_id: assignment["id"])

Cashramp::Client.mark_bot_agent_withdrawal_paid(
  payment_request_id: assignment["id"],
  payment_method_id: "pm_global_id",
  receipt: "https://example.com/receipt.png",
)
```

## API Reference

### Queries

| Method                                                                                  | Description                                                |
| --------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `available_countries`                                                                   | Fetch the countries Cashramp operates in                   |
| `market_rate(country_code:)`                                                            | Current deposit/withdrawal rates for a country             |
| `payment_method_types(country:)`                                                        | Available payment methods for a country (global ID)        |
| `rampable_assets`                                                                       | Supported cryptocurrencies and networks                    |
| `ramp_limits`                                                                           | Min/max transaction limits                                 |
| `ramp_quote(customer:, amount:, currency:, payment_method_type:, payment_type:, country:)` | Request a Direct Ramp quote (`payment_type` defaults to `"deposit"`) |
| `refresh_ramp_quote(ramp_quote_id:, amount:)`                                           | Refresh an existing quote                                  |
| `payment_request(reference:)`                                                           | Fetch a payment request by reference                       |
| `account`                                                                               | Account balance and deposit address                        |

### Mutations

#### Hosted Payments

| Method                                                                                                                                              | Description                  |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `initiate_hosted_payment(amount:, country_code:, payment_type:, first_name:, last_name:, email:, currency:, reference:, redirect_url:, metadata:)`  | Start a hosted payment       |
| `cancel_hosted_payment(payment_request_id:)`                                                                                                        | Cancel a hosted payment      |

#### Customer Management

| Method                                                                                       | Description                              |
| -------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `create_customer(first_name:, last_name:, email:, country:)`                                 | Create a new customer profile            |
| `add_payment_method(customer:, payment_method_type:, fields:, ownership:)`                   | Add a payment method to a customer       |

#### Direct Ramp - Deposits

| Method                                                                                                                            | Description                       |
| --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| `initiate_ramp_quote_deposit(ramp_quote_id:, reference:, phone_number:, bank_account_number:, onchain_transfer_info:)`            | Start a deposit from a quote      |
| `mark_deposit_as_paid(payment_request_id:, receipt:)`                                                                             | Confirm the user paid             |
| `cancel_deposit(payment_request_id:)`                                                                                             | Cancel a deposit                  |

#### Direct Ramp - Withdrawals

| Method                                                                                       | Description                       |
| -------------------------------------------------------------------------------------------- | --------------------------------- |
| `initiate_ramp_quote_withdrawal(ramp_quote_id:, payment_method_id:, reference:)`             | Start a withdrawal from a quote   |
| `mark_withdrawal_as_received(payment_request_id:)`                                           | Confirm the user received funds   |

#### Other

| Method                                                                  | Description                          |
| ----------------------------------------------------------------------- | ------------------------------------ |
| `confirm_transaction(payment_request:, transaction_hash:)`              | Confirm crypto transfer to escrow    |
| `withdraw_onchain(address:, amount_usd:, network:, metadata:)`          | Withdraw from balance to a wallet    |

#### Bot Agents

All bot agent methods target `/cashramp/bot/graphql` and require a `secret_key:` whose bearer APIKey is an Agent. `payment_request_id` accepts a P2P payment global ID and is mapped to the GraphQL `p2pPayment` argument internally.

| Method                                                                                                                | Returns                       | Description                                                                                |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------ |
| `bot_agent_profile`                                                                                                   | Agent profile hash            | Authenticated agent profile (id, balances, rates, margins, counts, ...)                    |
| `bot_agent_order_history(page:, per_page:, filter:)`                                                                  | `{ "data" => [...], "pagination" => {...} }` | Page/perPage paginated P2P payments. Filter keys: `:orderId`, `:status`, `:dateFrom`, `:dateTo`, `:paymentMethod` |
| `bot_agent_withdrawal_info(symbol:)`                                                                                  | Withdrawal info hash          | Onchain destination/network info for a crypto symbol                                       |
| `accept_bot_agent_withdrawal(payment_request_id:)`                                                                    | Boolean                       | Accept an assigned withdrawal request                                                      |
| `cancel_bot_agent_withdrawal(payment_request_id:)`                                                                    | Boolean                       | Cancel/decline an assigned withdrawal request                                              |
| `mark_bot_agent_deposit_received(payment_request_id:)`                                                                | Boolean                       | Acknowledge receipt of customer fiat for a deposit leg                                     |
| `mark_bot_agent_withdrawal_paid(payment_request_id:, payment_method_id:, receipt:)`                                   | Boolean                       | Acknowledge sending fiat for a withdrawal leg (`payment_method_id:` required)              |
| `update_bot_agent_rates(deposit_rate:, deposit_margin:, withdrawal_rate:, withdrawal_margin:)`                        | Boolean                       | Set agent rates/margins (only provided keys are sent)                                      |
| `update_bot_agent_payment_method_liquidity(amount_local:, payment_method_id:, payment_method_type:)`                  | P2P payment method hash       | Set local-currency liquidity for a payment method                                          |

#### `onchain_transfer_info` Hash

Used in `initiate_ramp_quote_deposit` to deliver stablecoins onchain:

| Key              | Type   | Description                           |
| ---------------- | ------ | ------------------------------------- |
| `:address`       | String | Destination wallet address            |
| `:cryptocurrency`| String | e.g. `"usd_tether"`, `"usd_coin"`     |
| `:network`       | String | e.g. `"celo"`, `"polygon"`, `"base"`  |

## Custom Queries

For advanced use cases, use `send_request` to execute custom GraphQL queries:

```ruby
query = <<~GRAPHQL
  query {
    availableCountries {
      id
      name
      code
      currency {
        isoCode
        name
      }
    }
  }
GRAPHQL

response = Cashramp::Client.send_request(
  name: "availableCountries",
  query: query,
)

puts response.result if response.success?
```

## Error Handling

All methods return a `Cashramp::Client::Response` struct with `success?`, `result`, and `error`:

```ruby
response = Cashramp::Client.market_rate(country_code: "GH")

if response.success?
  puts "Deposit rate:    #{response.result["depositRate"]}"
  puts "Withdrawal rate: #{response.result["withdrawalRate"]}"
else
  warn "Error: #{response.error}"
end
```

## Documentation

For detailed API documentation and webhook integration, visit the [Cashramp API docs](https://docs.cashramp.co).

## Support

- [API Documentation](https://docs.cashramp.co)
- [Support](mailto:cashramp@useaccrue.com)
- [Report Issues](https://github.com/rockets-hq/cashramp-sdk-ruby/issues)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
