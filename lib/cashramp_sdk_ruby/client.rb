# frozen_string_literal: true

module CashrampSdkRuby
  class Client
    include HTTParty

    attr_reader :env, :secret_key

    headers({
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{@secret_key}"
            })
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
        name: 'merchantAccount',
        query: Queries::ACCOUNT,
        variables: { reference: reference }
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

    # Query the Cashramp API directly
    # @param [Hash] :variables The Graphql query variables
    def send_request(_name, _query, _variables = {})
      response = HTTParty.post(@endpoint, body: { query: :query, variables: :variables })
      result = JSON.parse(response.body)
      if response.code == 200
        if block_given?
          send_response(success: true, result: yield(result[:data, :name]))
        else
          send_response(success: true, result: result[:data, :name])
        end
      else
        send_response(success: false, error: result)
      end
    rescue HTTParty::Error => e
      send_response(success: false, error: e.message)
    end

    private

    def send_response(success: true, result: nil, error: nil)
      Response.new(success, result, error)
    end

    def validate_configuration!
      raise ArgumentError, "Invalid environment. Can either be 'test' or 'live'." unless @env.in?(%i[test live])
      raise ArgumentError, 'Please provide your API secret key.' if @secret_key.nil?
    end

    def setup
      host = 'api.useacrrue.com'
      host = "staging.#{host}" if @env == :test
      @endpoint = "https://#{host}/cashramp/api/graphql"
    end
  end
end
