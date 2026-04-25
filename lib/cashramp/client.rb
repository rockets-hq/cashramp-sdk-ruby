module Cashramp
  module Client
    class << self
      include HTTParty

      attr_reader :env, :secret_key

      API_URLS = {
        live: "https://api.useaccrue.com/cashramp/api/graphql",
        test: "https://staging.api.useaccrue.com/cashramp/api/graphql",
      }.freeze

      BOT_API_URLS = {
        live: "https://api.useaccrue.com/cashramp/bot/graphql",
        test: "https://staging.api.useaccrue.com/cashramp/bot/graphql",
      }.freeze

      Response = Struct.new(:success?, :result, :error)

      def initialize(env: nil, secret_key: nil)
        @env = (env || ENV["CASHRAMP_ENV"] || :live).to_sym
        @secret_key = secret_key || ENV["CASHRAMP_SECRET_KEY"]

        validate_configuration!
        setup

        self
      end

      # ------- QUERIES -------

      # Fetch the countries that Cashramp is available in
      # @return [Response] result is an Array of Hashes with id, name, and code
      def available_countries
        send_request(
          name: "availableCountries",
          query: Queries::AVAILABLE_COUNTRIES,
        )
      end

      # Fetch the Cashramp market rate for a country
      # @param [String] country_code Two-letter ISO 3166-1 country code
      # @return [Response] result has depositRate and withdrawalRate
      def market_rate(country_code:)
        send_request(
          name: "marketRate",
          query: Queries::MARKET_RATE,
          variables: { countryCode: country_code },
        )
      end

      # Fetch the payment method types available in a country
      # @param [String] country The country's global ID
      def payment_method_types(country:)
        send_request(
          name: "p2pPaymentMethodTypes",
          query: Queries::PAYMENT_METHOD_TYPES,
          variables: { country: country },
        )
      end

      # Fetch the assets you can on/off-ramp with the Onchain Ramp
      def rampable_assets
        send_request(
          name: "rampableAssets",
          query: Queries::RAMPABLE_ASSETS,
        )
      end

      # Fetch the Onchain Ramp limits
      def ramp_limits
        send_request(
          name: "rampLimits",
          query: Queries::RAMP_LIMITS,
        )
      end

      # Fetch the details of a payment request
      # @param [String] reference Payment request reference
      def payment_request(reference:)
        send_request(
          name: "merchantPaymentRequest",
          query: Queries::PAYMENT_REQUEST,
          variables: { reference: reference },
        )
      end

      # Fetch the account information for the authenticated user
      def account
        send_request(
          name: "account",
          query: Queries::ACCOUNT,
        )
      end

      # Request a new Ramp Quote for a Direct Ramp payment
      # @param [String] customer Customer's global ID
      # @param [Numeric] amount Amount to ramp
      # @param [String] currency 'usd' or 'local_currency'
      # @param [String] payment_type 'deposit' or 'withdrawal' (default: 'deposit')
      # @param [String] payment_method_type Payment method identifier
      # @param [String] country Optional ISO 3166-1 country code
      def ramp_quote(customer:, amount:, currency:, payment_method_type:, payment_type: nil, country: nil)
        send_request(
          name: "rampQuote",
          query: Queries::RAMP_QUOTE,
          variables: {
            customer: customer,
            amount: amount,
            currency: currency,
            paymentType: payment_type || "deposit",
            paymentMethodType: payment_method_type,
            country: country,
          }.compact,
        )
      end

      # Refresh an existing Ramp Quote
      # @param [String] ramp_quote_id Quote's global ID
      # @param [Numeric] amount Optional new amount (keeps original if omitted)
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

      # Confirm a crypto transfer sent into Cashramp's Secure Escrow address
      def confirm_transaction(payment_request:, transaction_hash:)
        send_request(
          name: "confirmTransaction",
          query: Mutations::CONFIRM_TRANSACTION,
          variables: { paymentRequest: payment_request, transactionHash: transaction_hash },
        )
      end

      # Initiate a hosted payment request
      # @param [Numeric] amount Payment amount
      # @param [String] country_code Two-letter ISO 3166-1 country code
      # @param [String] payment_type 'deposit' or 'withdrawal'
      # @param [String] first_name Customer's first name
      # @param [String] last_name Customer's last name
      # @param [String] email Customer's email address
      # @param [String] currency Optional payment currency (default: 'usd')
      # @param [String] reference Optional payment request reference
      # @param [String] redirect_url Optional URL to redirect to after payment
      # @param [Hash] metadata Optional metadata echoed in webhooks
      def initiate_hosted_payment(amount:, country_code:, payment_type:, first_name:, last_name:, email:,
                                   currency: nil, reference: nil, redirect_url: nil, metadata: nil)
        send_request(
          name: "initiateHostedPayment",
          query: Mutations::INITIATE_HOSTED_PAYMENT,
          variables: {
            amount: amount,
            currency: currency || "usd",
            countryCode: country_code,
            paymentType: payment_type,
            reference: reference,
            redirectUrl: redirect_url,
            metadata: metadata,
            firstName: first_name,
            lastName: last_name,
            email: email,
          }.compact,
        )
      end

      # Cancel a hosted payment request
      def cancel_hosted_payment(payment_request_id:)
        send_request(
          name: "cancelHostedPayment",
          query: Mutations::CANCEL_HOSTED_PAYMENT,
          variables: { paymentRequest: payment_request_id },
        )
      end

      # Create a new customer profile
      def create_customer(first_name:, last_name:, email:, country:)
        send_request(
          name: "createCustomer",
          query: Mutations::CREATE_CUSTOMER,
          variables: { firstName: first_name, lastName: last_name, email: email, country: country },
        )
      end

      # Add a payment method for an existing customer
      # @param [String] customer Customer's global ID
      # @param [String] payment_method_type Payment method type identifier
      # @param [Array<Hash>] fields Payment method fields ([{ identifier:, value: }, ...])
      # @param [String] ownership Optional 'first_party' or 'third_party'
      def add_payment_method(customer:, payment_method_type:, fields:, ownership: nil)
        send_request(
          name: "addPaymentMethod",
          query: Mutations::ADD_PAYMENT_METHOD,
          variables: {
            customer: customer,
            paymentMethodType: payment_method_type,
            fields: fields,
            ownership: ownership,
          }.compact,
        )
      end

      # Withdraw from your balance to an onchain wallet address
      # @param [String] address Wallet address to withdraw to
      # @param [Numeric] amount_usd Amount to withdraw in USD
      # @param [String] network Optional network to withdraw on
      # @param [Hash] metadata Optional metadata for the withdrawal
      def withdraw_onchain(address:, amount_usd:, network: nil, metadata: nil)
        send_request(
          name: "withdrawOnchain",
          query: Mutations::WITHDRAW_ONCHAIN,
          variables: {
            address: address,
            amountUsd: amount_usd,
            network: network,
            metadata: metadata,
          }.compact,
        )
      end

      # Initiate a Ramp Quote deposit
      # @param [String] ramp_quote_id Quote's global ID
      # @param [String] reference Optional reference for the payment request
      # @param [String] phone_number Customer's phone number if paying via MoMo
      # @param [String] bank_account_number Customer's bank account number if paying via bank
      # @param [Hash] onchain_transfer_info Optional Hash with :address, :cryptocurrency, :network for onchain stablecoin delivery
      def initiate_ramp_quote_deposit(ramp_quote_id:, reference: nil, phone_number: nil,
                                       bank_account_number: nil, onchain_transfer_info: nil)
        send_request(
          name: "initiateRampQuoteDeposit",
          query: Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
          variables: {
            rampQuote: ramp_quote_id,
            reference: reference,
            phoneNumber: phone_number,
            bankAccountNumber: bank_account_number,
            onchainTransferInfo: onchain_transfer_info,
          }.compact,
        )
      end

      # Mark a deposit payment request as paid
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

      # Cancel a deposit payment request
      def cancel_deposit(payment_request_id:)
        send_request(
          name: "cancelDeposit",
          query: Mutations::CANCEL_DEPOSIT,
          variables: { paymentRequest: payment_request_id },
        )
      end

      # Initiate a Ramp Quote withdrawal
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

      # Mark a withdrawal payment request as received
      def mark_withdrawal_as_received(payment_request_id:)
        send_request(
          name: "markWithdrawalAsReceived",
          query: Mutations::MARK_WITHDRAWAL_AS_RECEIVED,
          variables: { paymentRequest: payment_request_id },
        )
      end

      # ------- BOT AGENT -------

      # Fetch the authenticated bot agent's profile
      # @return [Response] result is the agent profile hash
      def bot_agent_profile
        send_request(
          name: "profile",
          query: Queries::BOT_AGENT_PROFILE,
          endpoint: :bot,
        )
      end

      # Fetch the bot agent's order history (page/perPage pagination)
      # @param [Integer] page 1-indexed page number
      # @param [Integer] per_page Optional results per page (defaults to API default of 10)
      # @param [Hash] filter Optional filter ({ orderId:, status:, dateFrom:, dateTo:, paymentMethod: })
      # @return [Response] result is { "data" => [..], "pagination" => { ... } }
      def bot_agent_order_history(page:, per_page: nil, filter: nil)
        send_request(
          name: "orderHistory",
          query: Queries::BOT_AGENT_ORDER_HISTORY,
          variables: {
            page: page,
            perPage: per_page,
            filter: filter,
          }.compact,
          endpoint: :bot,
        )
      end

      # Fetch withdrawal info (networks, regexes) for a crypto symbol
      # @param [String] symbol Crypto symbol (e.g. "USDC")
      def bot_agent_withdrawal_info(symbol:)
        send_request(
          name: "withdrawalInfo",
          query: Queries::BOT_AGENT_WITHDRAWAL_INFO,
          variables: { symbol: symbol },
          endpoint: :bot,
        )
      end

      # Accept an assigned withdrawal request as a bot agent
      # @param [String] payment_request_id P2P payment global ID
      def accept_bot_agent_withdrawal(payment_request_id:)
        send_request(
          name: "acceptWithdrawal",
          query: Mutations::BOT_AGENT_ACCEPT_WITHDRAWAL,
          variables: { p2pPayment: payment_request_id },
          endpoint: :bot,
        )
      end

      # Cancel/decline an assigned withdrawal request as a bot agent
      # @param [String] payment_request_id P2P payment global ID
      def cancel_bot_agent_withdrawal(payment_request_id:)
        send_request(
          name: "cancelWithdrawal",
          query: Mutations::BOT_AGENT_CANCEL_WITHDRAWAL,
          variables: { p2pPayment: payment_request_id },
          endpoint: :bot,
        )
      end

      # Acknowledge receipt of customer fiat for a deposit leg as a bot agent
      # @param [String] payment_request_id P2P payment global ID
      def mark_bot_agent_deposit_received(payment_request_id:)
        send_request(
          name: "markDepositAsReceived",
          query: Mutations::BOT_AGENT_MARK_DEPOSIT_AS_RECEIVED,
          variables: { p2pPayment: payment_request_id },
          endpoint: :bot,
        )
      end

      # Acknowledge sending fiat for a withdrawal leg as a bot agent
      # @param [String] payment_request_id P2P payment global ID
      # @param [String] payment_method_id Payment method global ID the agent paid from
      # @param [String] receipt Optional receipt string
      def mark_bot_agent_withdrawal_paid(payment_request_id:, payment_method_id:, receipt: nil)
        send_request(
          name: "markWithdrawalAsPaid",
          query: Mutations::BOT_AGENT_MARK_WITHDRAWAL_AS_PAID,
          variables: {
            p2pPayment: payment_request_id,
            paymentMethod: payment_method_id,
            receipt: receipt,
          }.compact,
          endpoint: :bot,
        )
      end

      # Update bot agent rates and margins. Only provided keys are sent.
      # @param [Numeric, String] deposit_rate
      # @param [Numeric, String] deposit_margin
      # @param [Numeric, String] withdrawal_rate
      # @param [Numeric, String] withdrawal_margin
      def update_bot_agent_rates(deposit_rate: nil, deposit_margin: nil, withdrawal_rate: nil, withdrawal_margin: nil)
        send_request(
          name: "updateRates",
          query: Mutations::BOT_AGENT_UPDATE_RATES,
          variables: {
            depositRate: deposit_rate,
            depositMargin: deposit_margin,
            withdrawalRate: withdrawal_rate,
            withdrawalMargin: withdrawal_margin,
          }.compact,
          endpoint: :bot,
        )
      end

      # Set the local-currency liquidity available for a bot agent payment method
      # @param [Numeric, String] amount_local Required local-currency amount
      # @param [String] payment_method_id Optional existing P2PPaymentMethod global ID
      # @param [String] payment_method_type Optional payment method type identifier
      def update_bot_agent_payment_method_liquidity(amount_local:, payment_method_id: nil, payment_method_type: nil)
        send_request(
          name: "updatePaymentMethodLiquidity",
          query: Mutations::BOT_AGENT_UPDATE_PAYMENT_METHOD_LIQUIDITY,
          variables: {
            amountLocal: amount_local,
            paymentMethod: payment_method_id,
            paymentMethodType: payment_method_type,
          }.compact,
          endpoint: :bot,
        )
      end

      # Query the Cashramp API directly
      # @param [String] name Name of the GraphQL operation
      # @param [String] query GraphQL query or mutation string
      # @param [Hash] variables The GraphQL query variables
      # @param [Symbol] endpoint Which Cashramp schema to target (:merchant or :bot). Defaults to :merchant.
      # @return [Response] Response object with success status, result data, or error message
      def send_request(name:, query:, variables: {}, endpoint: :merchant)
        url = endpoint == :bot ? @bot_endpoint : @endpoint
        response = HTTParty.post(
          url,
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
        @bot_endpoint = BOT_API_URLS[@env]
      end
    end
  end
end
