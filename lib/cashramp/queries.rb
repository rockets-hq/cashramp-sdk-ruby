# frozen_string_literal: true

module Cashramp
  module Client
    class Queries
      AVAILABLE_COUNTRIES = <<~GRAPHQL
      query {
        availableCountries {
          id
          name
          code
        }
      }
    GRAPHQL

      MARKET_RATE = <<~GRAPHQL
        query ($countryCode: String!) {
          marketRate(countryCode: $countryCode) {
            depositRate
            withdrawalRate
          }
        }
    GRAPHQL

      PAYMENT_METHOD_TYPES = <<~GRAPHQL
        query ($country: ID!) {
          p2pPaymentMethodTypes(country: $country) {
            id
            identifier
            label
            fields {
              label
              identifier
              required
            }
          }
        }
      GRAPHQL

      RAMPABLE_ASSETS = <<~GRAPHQL
        query {
          rampableAssets {
            name
            symbol
            networks
            contractAddress
          }
        }
      GRAPHQL

      RAMP_LIMITS = <<~GRAPHQL
        query {
          rampLimits {
            minimumDepositUsd
            maximumDepositUsd
            minimumWithdrawalUsd
            maximumWithdrawalUsd
            dailyLimitUsd
          }
        }
      GRAPHQL

      PAYMENT_REQUEST = <<~GRAPHQL
        query ($reference: String!) {
          merchantPaymentRequest(reference: $reference) {
            id
            paymentType
            hostedLink
            amount
            currency
            reference
            status
          }
        }
      GRAPHQL

      ACCOUNT = <<~GRAPHQL
        query {
          account {
            id
            accountBalance
            depositAddress
          }
        }
        GRAPHQL
    end
  end
end