module Cashramp
  module Client
    class Mutations
      CONFIRM_TRANSACTION = <<~GRAPHQL
        mutation ($paymentRequest: ID!, $transactionHash: String!) {
          confirmTransaction(paymentRequest: $paymentRequest, transactionHash: $transactionHash)
        }
      GRAPHQL
  
      INITIATE_HOSTED_PAYMENT = <<~GRAPHQL
        mutation ($amount: Decimal!, $currency: P2PPaymentCurrency, $countryCode: String!, $email: String!, $paymentType: P2PPaymentTypeType!, $reference: String!, $firstName: String!, $lastName: String!, $redirectUrl: String) {
          initiateHostedPayment(
            amount: $amount,
            currency: $currency,
            countryCode: $countryCode,
            email: $email,
            paymentType: $paymentType,
            reference: $reference,
            firstName: $firstName,
            lastName: $lastName,
            redirectUrl: $redirectUrl
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
        mutation ($customer: ID!, $paymentMethodType: ID!, $fields: [P2PPaymentMethodFieldInput!]!) {
          addPaymentMethod(customer: $customer, p2pPaymentMethodType: $paymentMethodType, fields: $fields) {
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
        mutation ($address: String!, $amountUsd: Decimal!) {
          withdrawOnchain(address: $address, amountUsd: $amountUsd) {
            id
            status
          }
        }
      GRAPHQL

      INITIATE_RAMP_QUOTE_DEPOSIT = <<~GRAPHQL
        mutation ($rampQuote: ID!, $reference: String) {
          initiateRampQuoteDeposit(rampQuote: $rampQuote, reference: $reference) {
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
    end
  end
end