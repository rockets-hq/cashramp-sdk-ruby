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
    end
  end
end
