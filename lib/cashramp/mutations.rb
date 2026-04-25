module Cashramp
  module Client
    class Mutations
      CONFIRM_TRANSACTION = <<~GRAPHQL
        mutation ($paymentRequest: ID!, $transactionHash: String!) {
          confirmTransaction(paymentRequest: $paymentRequest, transactionHash: $transactionHash)
        }
      GRAPHQL

      INITIATE_HOSTED_PAYMENT = <<~GRAPHQL
        mutation ($amount: Decimal!, $currency: P2PPaymentCurrency, $countryCode: String!, $email: String!, $paymentType: P2PPaymentTypeType!, $reference: String!, $firstName: String!, $lastName: String!, $redirectUrl: String, $metadata: JSON) {
          initiateHostedPayment(
            amount: $amount,
            currency: $currency,
            countryCode: $countryCode,
            email: $email,
            paymentType: $paymentType,
            reference: $reference,
            firstName: $firstName,
            lastName: $lastName,
            redirectUrl: $redirectUrl,
            metadata: $metadata
          ) {
            id
            hostedLink
            status
          }
        }
      GRAPHQL

      CANCEL_HOSTED_PAYMENT = <<~GRAPHQL
        mutation ($paymentRequest: ID!) {
          cancelHostedPayment(paymentRequest: $paymentRequest)
        }
      GRAPHQL

      CREATE_CUSTOMER = <<~GRAPHQL
        mutation ($email: String!, $firstName: String!, $lastName: String!, $country: ID!) {
          createCustomer(email: $email, firstName: $firstName, lastName: $lastName, country: $country) {
            id
            email
            firstName
            lastName
            country {
              id
              name
              code
            }
          }
        }
      GRAPHQL

      ADD_PAYMENT_METHOD = <<~GRAPHQL
        mutation ($customer: ID!, $paymentMethodType: String!, $fields: [P2PPaymentMethodFieldInput!]!, $ownership: P2PPaymentMethodOwnership) {
          addPaymentMethod(customer: $customer, paymentMethodType: $paymentMethodType, fields: $fields, ownership: $ownership) {
            id
            value
            fields {
              identifier
              value
            }
          }
        }
      GRAPHQL

      WITHDRAW_ONCHAIN = <<~GRAPHQL
        mutation ($address: String!, $amountUsd: Decimal!, $network: String, $metadata: JSON) {
          withdrawOnchain(address: $address, amountUsd: $amountUsd, network: $network, metadata: $metadata) {
            id
            status
          }
        }
      GRAPHQL

      INITIATE_RAMP_QUOTE_DEPOSIT = <<~GRAPHQL
        mutation ($rampQuote: ID!, $reference: String, $phoneNumber: String, $bankAccountNumber: String, $onchainTransferInfo: OnchainTransferInfo) {
          initiateRampQuoteDeposit(
            rampQuote: $rampQuote,
            reference: $reference,
            phoneNumber: $phoneNumber,
            bankAccountNumber: $bankAccountNumber,
            onchainTransferInfo: $onchainTransferInfo
          ) {
            id
            status
            agent
            paymentDetails
            exchangeRate
            amountLocal
            amountUsd
            expiresAt
          }
        }
      GRAPHQL

      MARK_DEPOSIT_AS_PAID = <<~GRAPHQL
        mutation ($paymentRequest: ID!, $receipt: String) {
          markDepositAsPaid(paymentRequest: $paymentRequest, receipt: $receipt)
        }
      GRAPHQL

      CANCEL_DEPOSIT = <<~GRAPHQL
        mutation ($paymentRequest: ID!) {
          cancelDeposit(paymentRequest: $paymentRequest)
        }
      GRAPHQL

      INITIATE_RAMP_QUOTE_WITHDRAWAL = <<~GRAPHQL
        mutation ($rampQuote: ID!, $paymentMethod: ID!, $reference: String) {
          initiateRampQuoteWithdrawal(
            rampQuote: $rampQuote,
            paymentMethod: $paymentMethod,
            reference: $reference
          ) {
            id
            status
            agent
            paymentDetails
            exchangeRate
            amountUsd
            amountLocal
          }
        }
      GRAPHQL

      MARK_WITHDRAWAL_AS_RECEIVED = <<~GRAPHQL
        mutation ($paymentRequest: ID!) {
          markWithdrawalAsReceived(paymentRequest: $paymentRequest)
        }
      GRAPHQL

      # ---------- Bot Agent ----------

      BOT_AGENT_ACCEPT_WITHDRAWAL = <<~GRAPHQL
        mutation ($p2pPayment: ID!) {
          acceptWithdrawal(p2pPayment: $p2pPayment)
        }
      GRAPHQL

      BOT_AGENT_CANCEL_WITHDRAWAL = <<~GRAPHQL
        mutation ($p2pPayment: ID!) {
          cancelWithdrawal(p2pPayment: $p2pPayment)
        }
      GRAPHQL

      BOT_AGENT_MARK_DEPOSIT_AS_RECEIVED = <<~GRAPHQL
        mutation ($p2pPayment: ID!) {
          markDepositAsReceived(p2pPayment: $p2pPayment)
        }
      GRAPHQL

      BOT_AGENT_MARK_WITHDRAWAL_AS_PAID = <<~GRAPHQL
        mutation ($p2pPayment: ID!, $paymentMethod: ID!, $receipt: String) {
          markWithdrawalAsPaid(
            p2pPayment: $p2pPayment,
            paymentMethod: $paymentMethod,
            receipt: $receipt
          )
        }
      GRAPHQL

      BOT_AGENT_UPDATE_RATES = <<~GRAPHQL
        mutation ($depositRate: Decimal, $depositMargin: Decimal, $withdrawalRate: Decimal, $withdrawalMargin: Decimal) {
          updateRates(
            depositRate: $depositRate,
            depositMargin: $depositMargin,
            withdrawalRate: $withdrawalRate,
            withdrawalMargin: $withdrawalMargin
          )
        }
      GRAPHQL

      BOT_AGENT_UPDATE_PAYMENT_METHOD_LIQUIDITY = <<~GRAPHQL
        mutation ($paymentMethod: ID, $paymentMethodType: String, $amountLocal: Decimal!) {
          updatePaymentMethodLiquidity(
            paymentMethod: $paymentMethod,
            paymentMethodType: $paymentMethodType,
            amountLocal: $amountLocal
          ) {
            id
            value
            displayValue
            localCurrencyAvailable
            deleted
            ownership
            designation
            instant
          }
        }
      GRAPHQL
    end
  end
end
