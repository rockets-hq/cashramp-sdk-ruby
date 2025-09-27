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
        test: 'https://staging.api.useaccrue.com/cashramp/api/graphql'
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
          variables: { country: country_code }
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
          name: 'merchantAccount',
          query: Queries::ACCOUNT,
        )
      end
  
      # MUTATIONS
  
      # Confirm a crypto transfer sent into the Cashramp's Secure Escrow address
      def confirm_transaction(payment_request:, transaction_hash:)
        send_request(
          name: 'confirmTransaction',
          query: Mutations::CONFIRM_TRANSACTION,
          variables: { paymentRequest: payment_request, transactionHash: transaction_hash }
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

      # Get a ramp quote for currency conversion
      # @param [String] :customer Global ID of the paying customer
      # @param [Numeric] :amount Amount to convert
      # @param [String] :currency 'local_currency' or 'usd'
      # @param [String] :payment_type 'deposit' or 'withdrawal'
      # @param [String] :payment_method_type Payment rail identifier (e.g., 'bank_transfer_ng')
      # @param [String] :country Optional ISO 3166-2 country code
      def ramp_quote(customer:, amount:, currency:, payment_type:, payment_method_type:, country: nil)
        send_request(
          name: 'rampQuote',
          query: Queries::RAMP_QUOTE,
          variables: { 
            customer: customer,
            amount: amount,
            currency: currency,
            paymentType: payment_type,
            paymentMethodType: payment_method_type,
            country: country
          }.compact
        )
      end

      # Refresh an existing ramp quote
      # @param [String] :ramp_quote_id ID of the quote to refresh
      # @param [Numeric] :amount Optional new amount (keeps original if omitted)
       def refresh_ramp_quote(ramp_quote_id:, amount: nil)
         send_request(
           name: 'refreshRampQuote',
           query: Queries::REFRESH_RAMP_QUOTE,
           variables: {
             rampQuote: ramp_quote_id,
             amount: amount
           }.compact
         )
       end

      # Initiate a ramp quote deposit (convert local currency to stablecoins)
      # @param [String] :ramp_quote_id Quote ID from rampQuote query
      # @param [String] :reference Optional unique reference for reconciliation
      # @param [String] :phone_number Customer's phone number if paying via MoMo
      # @param [String] :bank_account_number Customer's bank account number if paying via bank
      def initiate_ramp_quote_deposit(ramp_quote_id:, reference: nil, phone_number: nil, bank_account_number: nil)
        send_request(
          name: 'initiateRampQuoteDeposit',
          query: Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
          variables: {
            rampQuote: ramp_quote_id,
            reference: reference,
            phoneNumber: phone_number,
            bankAccountNumber: bank_account_number
          }.compact
        )
      end

      # Mark a deposit as paid by the customer
      # @param [String] :payment_request_id Deposit request ID
      # @param [String] :receipt Optional payment proof URL
      def mark_deposit_as_paid(payment_request_id:, receipt: nil)
        send_request(
          name: 'markDepositAsPaid',
          query: Mutations::MARK_DEPOSIT_AS_PAID,
          variables: {
            paymentRequest: payment_request_id,
            receipt: receipt
          }.compact
        )
      end

      # Cancel an initiated deposit
      # @param [String] :payment_request_id Deposit request ID to cancel
      def cancel_deposit(payment_request_id:)
        send_request(
          name: 'cancelDeposit',
          query: Mutations::CANCEL_DEPOSIT,
          variables: { paymentRequest: payment_request_id }
        )
      end

      # Initiate a ramp quote withdrawal (convert stablecoins to local currency)
      # @param [String] :ramp_quote_id Quote ID from rampQuote query
      # @param [String] :payment_method_id Customer's payment method ID
      # @param [String] :reference Optional unique reference for reconciliation
      def initiate_ramp_quote_withdrawal(ramp_quote_id:, payment_method_id:, reference: nil)
        send_request(
          name: 'initiateRampQuoteWithdrawal',
          query: Mutations::INITIATE_RAMP_QUOTE_WITHDRAWAL,
          variables: {
            rampQuote: ramp_quote_id,
            paymentMethod: payment_method_id,
            reference: reference
          }.compact
        )
      end

      # Mark a withdrawal as received by the customer
      # @param [String] :payment_request_id Withdrawal request ID
      def mark_withdrawal_as_received(payment_request_id:)
        send_request(
          name: 'markWithdrawalAsReceived',
          query: Mutations::MARK_WITHDRAWAL_AS_RECEIVED,
          variables: { paymentRequest: payment_request_id }
        )
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
