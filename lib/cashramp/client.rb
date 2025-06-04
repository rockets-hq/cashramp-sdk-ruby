module Cashramp
  module Client
    class << self
      include HTTParty

      attr_reader :env, :secret_key

      headers({
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{@secret_key}"
      })

      API_URLS = {
        live: 'https://api.cashramp.com/graphql',
        test: 'https://api.test.cashramp.com/graphql'
      }.freeze

      Response = Struct.new(:success?, :result, :error)

      def initialize(env: :live, secret_key: nil)
        @env = env
        @secret_key = secret_key || ENV['CASHRAMP_SECRET_KEY']
        validate_configuration!
        setup
      end

      # QUERIES
      #
      # Fetch the countries that Cashramp is available in
      def available_countries
        send_request(
          name: 'availableCountries',
          query: Queries::AVAILABLE_COUNTRIES
        )
      end

      # Fetch the Cashramp market rate for a country
      def market_rate(country_code:)
        send_request(
          name: 'marketRate',
          query: Queries::MARKET_RATE,
          variables: { countryCode: country_code }
        )
      end

      # Fetch the payment methods available in a country
      def payment_method_types(country_code:)
        send_request(
          name: 'p2pPaymentMethodTypes',
          query: Queries::PAYMENT_METHOD_TYPES,
          variables: { countryCode: country_code }
        )
      end

      # Fetch the assets you can on/off-ramp with the Onchain Ramp
      def rampable_assets
        send_request(
          name: 'rampableAssets',
          query: Queries::RAMPABLE_ASSETS
        )
      end

      # Fetch the Onchain Ramp limits
      def ramp_limits
        send_request(
          name: 'rampLimits',
          query: Queries::RAMP_LIMITS
        )
      end

      # Fetch the details of a payment request
      def payment_request(reference:)
        send_request(
          name: 'merchantPaymentRequest',
          query: Queries::PAYMENT_REQUEST,
          variables: { reference: reference }
        )
      end

      # Fetch the details of an account
      def account
        send_request(
          name: 'account',
          query: Queries::ACCOUNT,
        )
      end

      # Fetch the details of an onchain withdrawal
      def onchain_withdrawal(withdrawal_id:)
        send_request(
          name: 'onchainWithdrawal',
          query: Queries::ONCHAIN_WITHDRAWAL,
          variables: { withdrawalId: withdrawal_id }
        )
      end

      def ramp_quote(customer:, amount:, currency:, payment_method_type:)
        send_request(
          name: 'rampQuote',
          query: Queries::RAMP_QUOTE,
          variables: { customer: customer, amount: amount, currency: currency, paymentMethodType: payment_method_type }
        )
      end

      def refresh_ramp_quote(ramp_quote:, amount:)
        send_request(
          name: 'refreshRampQuote',
          query: Queries::REFRESH_RAMP_QUOTE,
          variables: { rampQuote: ramp_quote, amount: amount }
        )
      end

      # MUTATIONS
  
      # Confirm a crypto transfer sent into the Cashramp's Secure Escrow address
      def confirm_transaction(payment_request:, transaction_hash:)
        send_request(
          name: 'confirmTransaction',
          query: Mutations::CONFIRM_TRANSACTION,
          variables: { paymentRequest: payment_request, trnasactionHash: transaction_hash }
        )
      end

      def initiate_hosted_payment(payment_params = {})
        send_request(
          name: 'initiateHostedPaymnet',
          query: Mutations::INITIATE_HOSTED_PAYMENT,
          variables: {
            amount: payment_params[:amount],
            currency: payment_params[:currency] || 'usd',
            countryCode: payment_params[:country_code],
            paymentType: payment_params[:payment_type],
            reference: payment_params[:reference],
            redirect_url: payment_params[:redirect_url],
            firstName: payment_params[:first_name],
            lastName: payment_params[:last_name],
            email: payment_params[:email]
          }
        )
      end

      def cancel_hosted_payment(payment_request = {})
        send_request(name: 'cancelHostedPayment', query: Mutations::CANCEL_HOSTED_PAYMENT, variables: payment_request)
      end

      # Create a new customer profile
      #
      # @param [Hash] :customer_details
      # @option customer_details [String] :first_name
      # @option customer_details [String] :last_name
      # @option customer_details [String] :email
      # @option customer_details [String] :country
      def create_customer(customer_details = {})
        send_request(name: 'createCustomer', query: Mutations::CREATE_CUSTOMER, variables: customer_details)
      end

      # Add a payment method for an existing customer
      #
      # @param [Hash] :payment_method_options
      # @param [String] :payment_method_options[:customer]
      # @param [String] :payment_method_options[:p2p_payment_method_type]
      # @param [Hash] :payment_method_options[:fields]
      def add_payment_method(payment_method_options = {})
        send_request(name: 'addPaymentMethod', query: Mutations::ADD_PAYMENT_METHOD, variables: payment_method_options)
      end

      # Withdraw from your balance to an onchain wallet address
      # @param [Hash] :withdraw_options
      # @param [String] :withdraw_options[:address]
      # @param [Numeric] :withdraw_options[:amount_usd]
      def withdraw_onchain(withdraw_options)
        send_request(name: 'withdrawOnchain', query: Mutations::WITHDRAW_ONCHAIN, variables: withdraw_options)
      end

      # Initiate a deposit for a Ramp Quote
      # @param [String] :ramp_quote
      # @param [String] :reference
      def initiate_ramp_quote_deposit(ramp_quote:, reference:)
        send_request(name: 'initiateRampQuoteDeposit', query: Mutations::INITIATE_RAMP_QUOTE_DEPOSIT, variables: { rampQuote: ramp_quote, reference: reference })
      end

      # Mark a deposit as paid
      # @param [String] :payment_request
      # @param [String] :receipt
      def mark_deposit_as_paid(payment_request:, receipt:)
        send_request(name: 'markDepositAsPaid', query: Mutations::MARK_DEPOSIT_AS_PAID, variables: { paymentRequest: payment_request, receipt: receipt })
      end

      # Cancel a deposit
      def cancel_deposit(payment_request:)
        send_request(name: 'cancelDeposit', query: Mutations::CANCEL_DEPOSIT, variables: { paymentRequest: payment_request })
      end

      # Query the Cashramp API directly
      # @param [Hash] :variables The Graphql query variables
      def send_request(name:, query:, variables: {})
        response = HTTParty.post(
          @endpoint, 
          body: {
            query: query, 
            variables: variables 
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@secret_key}"
          }
        )
  
        if response.code == 200
          begin
            result = JSON.parse(response.body)
            if result['errors']
              send_response(success: false, error: result['errors'][0]['message'])
            else
              send_response(success: true, result: result['data'][name])
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
        raise ArgumentError, 'Please provide your API secret key.' if @secret_key.nil?
      end

      def setup
        @endpoint = API_URLS[@env]
      end
    end
  end
end
