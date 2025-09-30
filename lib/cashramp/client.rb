module Cashramp
  module Client
    class << self
      include HTTParty

      attr_reader :env, :secret_key

      headers({
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@secret_key}",
      })

      API_URLS = {
        live: "https://api.useaccrue.com/cashramp/api/graphql",
        test: "https://staging.api.useaccrue.com/cashramp/api/graphql",
      }.freeze

      Response = Struct.new(:success?, :result, :error)

      def initialize(env:, secret_key:)
        @env = env || ENV["CASHRAMP_ENV"] || :live
        @secret_key = secret_key || ENV["CASHRAMP_SECRET_KEY"]

        validate_configuration!
        setup
      end

      # ------- QUERIES -------

      # Fetch the countries that Cashramp is available in
      # @return [Response] Response object with success status and result containing array of countries
      # @return [Array<Hash>] result.countries Array of country objects with id, name, and code
      def available_countries
        send_request(
          name: "availableCountries",
          query: Queries::AVAILABLE_COUNTRIES,
        )
      end

      # Fetch the Cashramp market rate for a country
      # @param [String] country_code ISO country code to get market rates for
      # @return [Response] Response object with success status and result containing market rates
      # @return [Hash] result.market_rate Object with depositRate and withdrawalRate
      def market_rate(country_code:)
        send_request(
          name: "marketRate",
          query: Queries::MARKET_RATE,
          variables: { countryCode: country_code },
        )
      end

      # Fetch the payment methods available in a country
      # @param [String] country Country ID to get payment method types for
      # @return [Response] Response object with success status and result containing payment method types
      # @return [Array<Hash>] result.payment_method_types Array of payment method objects with id, identifier, label, and fields
      def payment_method_types(country:)
        send_request(
          name: "p2pPaymentMethodTypes",
          query: Queries::PAYMENT_METHOD_TYPES,
          variables: { country: country },
        )
      end

      # Fetch the assets you can on/off-ramp with the Onchain Ramp
      # @return [Response] Response object with success status and result containing rampable assets
      # @return [Array<Hash>] result.rampable_assets Array of asset objects with name, symbol, networks, and contractAddress
      def rampable_assets
        send_request(
          name: "rampableAssets",
          query: Queries::RAMPABLE_ASSETS,
        )
      end

      # Fetch the Onchain Ramp limits
      # @return [Response] Response object with success status and result containing ramp limits
      # @return [Hash] result.ramp_limits Object with minimumDepositUsd, maximumDepositUsd, minimumWithdrawalUsd, maximumWithdrawalUsd, and dailyLimitUsd
      def ramp_limits
        send_request(
          name: "rampLimits",
          query: Queries::RAMP_LIMITS,
        )
      end

      # Fetch the details of a payment request
      # @param [String] reference Payment request reference to fetch details for
      # @return [Response] Response object with success status and result containing payment request details
      # @return [Hash] result.payment_request Object with id, paymentType, hostedLink, amount, currency, reference, and status
      def payment_request(reference:)
        send_request(
          name: "merchantPaymentRequest",
          query: Queries::PAYMENT_REQUEST,
          variables: { reference: reference },
        )
      end

      # Fetch the details of an account
      # @return [Response] Response object with success status and result containing account details
      # @return [Hash] result.account Object with id, accountBalance, and depositAddress
      def account
        send_request(
          name: "account",
          query: Queries::ACCOUNT,
        )
      end

      # Get a ramp quote for currency conversion
      # @param [String] customer Global ID of the paying customer
      # @param [Numeric] amount Amount to convert
      # @param [String] currency 'local_currency' or 'usd'
      # @param [String] payment_type 'deposit' or 'withdrawal'
      # @param [String] payment_method_type Payment rail identifier (e.g., 'bank_transfer_ng')
      # @param [String] country Optional ISO 3166-2 country code
      # @return [Response] Response object with success status and result containing quote details
      # @return [Hash] result.ramp_quote Object with id, exchangeRate, and paymentType
      def ramp_quote(customer:, amount:, currency:, payment_type:, payment_method_type:, country: nil)
        send_request(
          name: "rampQuote",
          query: Queries::RAMP_QUOTE,
          variables: {
            customer: customer,
            amount: amount,
            currency: currency,
            paymentType: payment_type,
            paymentMethodType: payment_method_type,
            country: country,
          }.compact,
        )
      end

      # Refresh an existing ramp quote
      # @param [String] ramp_quote_id ID of the quote to refresh
      # @param [Numeric] amount Optional new amount (keeps original if omitted)
      # @return [Response] Response object with success status and result containing refreshed quote
      # @return [Hash] result.refreshed_quote Object with id, exchangeRate, and paymentType
      def refresh_ramp_quote(ramp_quote_id:, amount: nil)
        send_request(
          name: "refreshRampQuote",
          query: Queries::REFRESH_RAMP_QUOTE,
          variables: {
            rampQuote: ramp_quote_id,
            amount: amount,
          }.compact,
        )
      end

      # ------- MUTATIONS -------

      # Confirm a crypto transfer sent into the Cashramp's Secure Escrow address
      # @param [String] payment_request Payment request ID to confirm
      # @param [String] transaction_hash Transaction hash of the crypto transfer
      # @return [Response] Response object with success status and confirmation result
      def confirm_transaction(payment_request:, transaction_hash:)
        send_request(
          name: "confirmTransaction",
          query: Mutations::CONFIRM_TRANSACTION,
          variables: { paymentRequest: payment_request, transactionHash: transaction_hash },
        )
      end

      # Initiate a hosted payment request
      # @param [Numeric] amount Payment amount
      # @param [String] currency Payment currency (default: "usd")
      # @param [String] country_code Country code for the payment
      # @param [String] payment_type Type of payment
      # @param [String] reference Unique reference for the payment
      # @param [String] redirect_url URL to redirect after payment
      # @param [String] first_name Customer's first name
      # @param [String] last_name Customer's last name
      # @param [String] email Customer's email address
      # @return [Response] Response object with success status and result containing payment details
      # @return [Hash] result.payment_request Object with id, hostedLink, and status
      def initiate_hosted_payment(amount:, currency:, country_code:, payment_type:, reference:, redirect_url:, first_name:, last_name:, email:)
        send_request(
          name: "initiateHostedPayment",
          query: Mutations::INITIATE_HOSTED_PAYMENT,
          variables: {
            amount: amount,
            currency: currency || "usd",
            countryCode: country_code,
            paymentType: payment_type,
            reference: reference,
            redirect_url: redirect_url,
            firstName: first_name,
            lastName: last_name,
            email: email,
          },
        )
      end

      # Cancel a hosted payment request
      # @param [String] payment_request_id ID of the payment request to cancel
      # @return [Response] Response object with success status and cancellation result
      def cancel_hosted_payment(payment_request_id:)
        send_request(name: "cancelHostedPayment", query: Mutations::CANCEL_HOSTED_PAYMENT, variables: { paymentRequest: payment_request_id })
      end

      # Create a new customer profile
      #
      # @param [String] first_name Customer's first name
      # @param [String] last_name Customer's last name
      # @param [String] email Customer's email address
      # @param [String] country Country ID for the customer
      # @return [Response] Response object with success status and result containing customer details
      # @return [Hash] result.customer Object with id, email, firstName, lastName, and country
      def create_customer(first_name:, last_name:, email:, country:)
        send_request(name: "createCustomer", query: Mutations::CREATE_CUSTOMER, variables: { firstName: first_name, lastName: last_name, email: email, country: country })
      end

      # Add a payment method for an existing customer
      #
      # @param [String] customer Customer ID
      # @param [String] payment_method_type Payment method type
      # @param [Hash] fields Payment method fields
      # @return [Response] Response object with success status and result containing payment method details
      # @return [Hash] result.payment_method Object with id, value, and fields
      def add_payment_method(customer:, payment_method_type:, fields:)
        send_request(name: "addPaymentMethod", query: Mutations::ADD_PAYMENT_METHOD, variables: { customer: customer, paymentMethodType: payment_method_type, fields: fields })
      end

      # Withdraw from your balance to an onchain wallet address
      # @param [String] address Onchain wallet address to withdraw to
      # @param [Numeric] amount_usd Amount to withdraw in USD
      # @return [Response] Response object with success status and result containing withdrawal details
      # @return [Hash] result.withdrawal Object with id and status
      def withdraw_onchain(address:, amount_usd:)
        send_request(name: "withdrawOnchain", query: Mutations::WITHDRAW_ONCHAIN, variables: { address: address, amountUsd: amount_usd })
      end

      # Initiate a ramp quote deposit (convert local currency to stablecoins)
      # @param [String] ramp_quote_id Quote ID from rampQuote query
      # @param [String] reference Optional unique reference for reconciliation
      # @param [String] phone_number Customer's phone number if paying via MoMo
      # @param [String] bank_account_number Customer's bank account number if paying via bank
      # @return [Response] Response object with success status and result containing deposit details
      # @return [Hash] result.deposit Object with id, status, agent, paymentDetails, exchangeRate, amountLocal, amountUsd, and expiresAt
      def initiate_ramp_quote_deposit(ramp_quote_id:, reference: nil, phone_number: nil, bank_account_number: nil)
        send_request(
          name: "initiateRampQuoteDeposit",
          query: Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
          variables: {
            rampQuote: ramp_quote_id,
            reference: reference,
            phoneNumber: phone_number,
            bankAccountNumber: bank_account_number,
          }.compact,
        )
      end

      # Mark a deposit as paid by the customer
      # @param [String] payment_request_id Deposit request ID
      # @param [String] receipt Optional payment proof URL
      # @return [Response] Response object with success status and payment confirmation result
      def mark_deposit_as_paid(payment_request_id:, receipt: nil)
        send_request(
          name: "markDepositAsPaid",
          query: Mutations::MARK_DEPOSIT_AS_PAID,
          variables: {
            paymentRequest: payment_request_id,
            receipt: receipt,
          }.compact,
        )
      end

      # Cancel an initiated deposit
      # @param [String] payment_request_id Deposit request ID to cancel
      # @return [Response] Response object with success status and cancellation result
      def cancel_deposit(payment_request_id:)
        send_request(
          name: "cancelDeposit",
          query: Mutations::CANCEL_DEPOSIT,
          variables: { paymentRequest: payment_request_id },
        )
      end

      # Initiate a ramp quote withdrawal (convert stablecoins to local currency)
      # @param [String] ramp_quote_id Quote ID from rampQuote query
      # @param [String] payment_method_id Customer's payment method ID
      # @param [String] reference Optional unique reference for reconciliation
      # @return [Response] Response object with success status and result containing withdrawal details
      # @return [Hash] result.withdrawal Object with id, status, agent, paymentDetails, exchangeRate, amountUsd, and amountLocal
      def initiate_ramp_quote_withdrawal(ramp_quote_id:, payment_method_id:, reference: nil)
        send_request(
          name: "initiateRampQuoteWithdrawal",
          query: Mutations::INITIATE_RAMP_QUOTE_WITHDRAWAL,
          variables: {
            rampQuote: ramp_quote_id,
            paymentMethod: payment_method_id,
            reference: reference,
          }.compact,
        )
      end

      # Mark a withdrawal as received by the customer
      # @param [String] payment_request_id Withdrawal request ID
      # @return [Response] Response object with success status and withdrawal confirmation result
      def mark_withdrawal_as_received(payment_request_id:)
        send_request(
          name: "markWithdrawalAsReceived",
          query: Mutations::MARK_WITHDRAWAL_AS_RECEIVED,
          variables: { paymentRequest: payment_request_id },
        )
      end

      # Query the Cashramp API directly
      # @param [String] name Name of the GraphQL operation
      # @param [String] query GraphQL query or mutation string
      # @param [Hash] variables The GraphQL query variables
      # @return [Response] Response object with success status, result data, or error message
      def send_request(name:, query:, variables: {})
        response = HTTParty.post(
          @endpoint,
          body: {
            query: query,
            variables: variables,
          }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{@secret_key}",
          },
        )

        if response.code == 200
          begin
            result = JSON.parse(response.body)
            if result["errors"]
              send_response(success: false, error: result["errors"][0]["message"])
            else
              send_response(success: true, result: result["data"][name])
            end
          rescue JSON::ParserError
            send_response(success: false, error: response.message)
          end
        else
          send_response(success: false, error: response.message)
        end
      rescue HTTParty::Error => e
        send_response(success: false, error: e.message)
      end

      private

      def send_response(success: true, result: nil, error: nil)
        Response.new(success, result, error)
      end

      def validate_configuration!
        raise ArgumentError, "Invalid environment" unless API_URLS.key?(@env)
        raise ArgumentError, "Please provide your API secret key." if @secret_key.nil?
      end

      def setup
        @endpoint = API_URLS[@env]
      end
    end
  end
end
