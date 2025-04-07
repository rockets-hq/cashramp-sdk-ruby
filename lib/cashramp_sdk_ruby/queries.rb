# frozen_string_literal: true

module CashrampSdkRuby
  class Queries
    AVAILABLE_COUNTRIES = `
      query {
        availableCountries {
          id
          name
          code
        }
      }
    `.freeze

    MARKET_RATE = `
      query ($countryCode: String!) {
        marketRate(countryCode: $countryCode) {
          depositRate
          withdrawalRate
        }
      }
    `.freeze

    PAYMENT_METHOD_TYPES = `
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
    `.freeze

    RAMPABLE_ASSETS = `
      query {
        rampableAssets {
          name
          symbol
          networks
          contractAddress
        }
      }
    `.freeze

    RAMP_LIMITS = `
      query {
        rampLimits {
          minimumDepositUsd
          maximumDepositUsd
          minimumWithdrawalUsd
          maximumWithdrawalUsd
          dailyLimitUsd
        }
      }
    `.freeze

    PAYMENT_REQUEST = `
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
    `.freeze

    ACCOUNT = `
      query {
        account {
          id
          accountBalance
          depositAddress
        }
      }
    `.freeze
  end
end
