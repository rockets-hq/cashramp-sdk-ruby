<p align="center">
  <a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://github.com/rockets-hq/cashramp-sdk-ruby/actions/workflows/test.yml/badge.svg" /></a>
  <img alt="Last Commit" src="https://badgen.net/github/last-commit/rockets-hq/cashramp-sdk-ruby" />
  <img alt="Downloads" src="https://img.shields.io/npm/dt/cashramp.svg"/>
  <a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://img.shields.io/github/stars/rockets-hq/cashramp-sdk-ruby.svg"/></a>
  <a href="https://github.com/rockets-hq/cashramp-sdk-ruby/"><img src="https://img.shields.io/npm/l/cashramp.svg"/></a>
</p>

# Cashramp SDK Ruby

This is the official Ruby gem for [Cashramp's API](https://cashramp.co/commerce).

### ➕ Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add cashramp
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install cashramp
```

## Usage

TODO: Write usage instructions here

### 👨🏾‍💻 Quick Start

```ruby
client = Cashramp::Client.initialize(env: :test, secret_key: 'test_key')

# Example: Fetch available countries
response = client.available_countries
# Check the response
if response.success?
  puts "Available countries: #{response.result}"
else
  puts "Error fetching available countries: #{response.error}"
end
```

## API Reference

### Queries

- `getAvailableCountries()`: Fetch the countries that Cashramp is available in
- `getMarketRate({ countryCode })`: Fetch the Cashramp market rate for a country
- `getPaymentMethodTypes({ country })`: Fetch the payment method types available in a country
- `getRampableAssets()`: Fetch the assets you can on/offramp with the Onchain Ramp
- `getRampLimits()`: Fetch the Onchain Ramp limits
- `getPaymentRequest({ reference })`: Fetch the details of a payment request
- `getAccount()`: Fetch the account information for the authenticated user.

### Mutations

- `confirmTransaction({ paymentRequest, transactionHash })`: Confirm a crypto transfer sent into Cashramp's Secure Escrow address
- `initiateHostedPayment({ amount, paymentType, countryCode, currency, email, reference, redirectUrl, firstName, lastName })`: Initiate a payment request
- `cancelHostedPayment({ paymentRequest })`: Cancel an ongoing payment request
- `createCustomer({ firstName, lastName, email, country })`: Create a new customer profile
- `addPaymentMethod({ customer, paymentMethodType, fields })`: Add a payment method for an existing customer
- `withdrawOnchain({ address, amountUsd })`:  Withdraw from your balance to an onchain wallet address

## Custom Queries

For advanced use cases where the provided methods don't cover your specific needs, you can use the `sendRequest` method to send custom GraphQL queries:

```ruby
query = <<-GRAPHQL
  query GetAvailableCountries {
    availableCountries {
      code
      name
    }
  }
GRAPHQL

# Call the send_request method
response = client.send_request(name: 'availableCountries', query: query, variables: {})

# Check the response
if response.success?
  puts "Available countries: #{response.result}"
else
  puts "Error fetching available countries: #{response.error}"
end
```

## Error Handling

All methods in the gem return a response object with a `success` boolean. When `success` is `false`, an `error` property will be available with details about the error. Always check the `success` property before accessing the `result`.

## Documentation

For detailed API documentation, visit [Cashramp's API docs](https://docs.cashramp.co).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cashramp_sdk_ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
