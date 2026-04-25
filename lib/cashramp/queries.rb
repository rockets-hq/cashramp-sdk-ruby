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

      RAMP_QUOTE = <<~GRAPHQL
        query ($customer: ID!, $amount: Decimal!, $currency: P2PPaymentCurrency!, $paymentType: PaymentTypeType, $paymentMethodType: String!, $country: String) {
          rampQuote(
            customer: $customer,
            amount: $amount,
            currency: $currency,
            paymentType: $paymentType,
            paymentMethodType: $paymentMethodType,
            country: $country
          ) {
            id
            exchangeRate
            paymentType
          }
        }
      GRAPHQL

      REFRESH_RAMP_QUOTE = <<~GRAPHQL
        query ($rampQuote: ID!, $amount: Decimal) {
          refreshRampQuote(rampQuote: $rampQuote, amount: $amount) {
            id
            exchangeRate
            paymentType
          }
        }
      GRAPHQL

      # ---------- Bot Agent ----------

      BOT_AGENT_PROFILE = <<~GRAPHQL
        query {
          profile {
            id
            email
            accountBalance
            escrowBalance
            bonusEarnings
            depositAddress
            verificationStatus
            autoUpdateDepositRate
            autoUpdateWithdrawalRate
            creditLine
            usedCreditLine
            depositMargin
            withdrawalMargin
            averageDepositRate
            averageWithdrawalRate
            depositsCompleted
            withdrawalsCompleted
            totalDepositFiatAmount
            totalDepositUsdAmount
            totalWithdrawalFiatAmount
            totalWithdrawalUsdAmount
            enforceReceiptUpload
            apiKey
          }
        }
      GRAPHQL

      BOT_AGENT_ORDER_HISTORY = <<~GRAPHQL
        query ($filter: OrderHistoryFilter, $page: Int!, $perPage: Int) {
          orderHistory(filter: $filter, page: $page, perPage: $perPage) {
            data {
              id
              status
              paymentType
              exchangeRate
              exchangeRateMinusSurcharge
              orderId
              source
              instant
              createdAt
              expiresAt
              expiresAtSecs
              reassigning
              reassignAfter
              reassignAfterSecs
              agentCutOfFees
              fxSpreadRevenue
            }
            pagination {
              page
              perPage
              total
            }
          }
        }
      GRAPHQL

      BOT_AGENT_WITHDRAWAL_INFO = <<~GRAPHQL
        query ($symbol: String!) {
          withdrawalInfo(symbol: $symbol) {
            symbol
            networks
            addressRegex
            memoRegex
          }
        }
      GRAPHQL
    end
  end
end
