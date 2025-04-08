require 'spec_helper'

RSpec.describe CashrampSDKRuby::Client do
  describe 'configuration' do
    it 'initializes with test environment' do
      CashrampSDKRuby::Client.initialize(env: :test, secret_key: 'test_key')
      expect(CashrampSDKRuby::Client.env).to eq(:test)
      expect(CashrampSDKRuby::Client.secret_key).to eq('test_key')
    end

    it 'raises error with invalid environment' do
      expect {
        CashrampSDKRuby::Client.initialize(env: :invalid, secret_key: 'test_key')
      }.to raise_error(ArgumentError, 'Invalid environment')
    end

    it 'raises error without secret key' do
      expect {
        CashrampSDKRuby::Client.initialize(env: :test, secret_key: nil)
      }.to raise_error(ArgumentError, 'Please provide your API secret key.')
    end
  end

  describe 'API requests' do
    before(:all) do
      CashrampSDKRuby::Client.initialize(env: :test, secret_key: 'test_key')
    end

    describe '.send_request' do
      let(:query) { 'query { test }' }
      let(:name) { 'test' }
      
      before do
        stub_request(:post, "https://api.test.cashramp.com/graphql")
          .with(
            body: {
              query: query,
              variables: {}
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_key'
            }
          )
          .to_return(status: status_code, body: response_body)
      end

      context 'when the request is successful' do
        let(:status_code) { 200 }
        let(:response_body) { { data: { test: 'result' } }.to_json }

        it 'returns a success response with data' do
          result = CashrampSDKRuby::Client.send_request(name: name, query: query)
          expect(result.success?).to be true
          expect(result.result).to eq('result')
          expect(result.error).to be_nil
        end
      end

      context 'when the request returns GraphQL errors' do
        let(:status_code) { 200 }
        let(:response_body) do 
          { 
            data: nil,
            errors: [{ message: 'GraphQL Error' }]
          }.to_json
        end

        it 'returns a failure response with error message' do
          result = CashrampSDKRuby::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
          expect(result.error).to eq('GraphQL Error')
        end
      end

      context 'when the request fails with HTTP error' do
        let(:status_code) { 400 }
        let(:response_body) { 'Bad Request' }

        it 'returns a failure response with status text' do
          result = CashrampSDKRuby::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
        end
      end

      context 'when HTTParty raises an error' do
        let(:status_code) { 400 }
        let(:response_body) { 'Bad Request' }
        before do
          allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new('Network error'))
        end

        it 'returns a failure response with error message' do
          result = CashrampSDKRuby::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
          expect(result.error).to eq('Network error')
        end
      end
    end

    describe '.available_countries' do
      it 'sends request with correct parameters' do
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'availableCountries',
          query: CashrampSDKRuby::Client::Queries::AVAILABLE_COUNTRIES
        )
        
        CashrampSDKRuby::Client.available_countries
      end
    end

    describe '.market_rate' do
      it 'sends request with correct parameters' do
        country_code = 'US'
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'marketRate',
          query: CashrampSDKRuby::Client::Queries::MARKET_RATE,
          variables: { countryCode: country_code }
        )
        
        CashrampSDKRuby::Client.market_rate(country_code: country_code)
      end
    end

    describe '.payment_method_types' do
      it 'sends request with correct parameters' do
        country_code = 'US'
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'p2pPaymentMethodTypes',
          query: CashrampSDKRuby::Client::Queries::PAYMENT_METHOD_TYPES,
          variables: { countryCode: country_code }
        )
        
        CashrampSDKRuby::Client.payment_method_types(country_code: country_code)
      end
    end

    describe '.rampable_assets' do
      it 'sends request with correct parameters' do
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'rampableAssets',
          query: CashrampSDKRuby::Client::Queries::RAMPABLE_ASSETS
        )
        
        CashrampSDKRuby::Client.rampable_assets
      end
    end

    describe '.ramp_limits' do
      it 'sends request with correct parameters' do
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'rampLimits',
          query: CashrampSDKRuby::Client::Queries::RAMP_LIMITS
        )
        
        CashrampSDKRuby::Client.ramp_limits
      end
    end

    describe '.payment_request' do
      it 'sends request with correct parameters' do
        reference = 'ref123'
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'merchantPaymentRequest',
          query: CashrampSDKRuby::Client::Queries::PAYMENT_REQUEST,
          variables: { reference: reference }
        )
        
        CashrampSDKRuby::Client.payment_request(reference: reference)
      end
    end

    describe '.account' do
      it 'sends request with correct parameters' do
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'merchantAccount',
          query: CashrampSDKRuby::Client::Queries::ACCOUNT,
        )
        
        CashrampSDKRuby::Client.account
      end
    end
  end

  describe 'Mutations' do
    describe '.confirm_transaction' do
      it 'sends request with correct parameters' do
        payment_request = 'pr123'
        transaction_hash = 'tx456'
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'confirmTransaction',
          query: CashrampSDKRuby::Client::Mutations::CONFIRM_TRANSACTION,
          variables: { 
            paymentRequest: payment_request, 
            trnasactionHash: transaction_hash 
          }
        )
        
        CashrampSDKRuby::Client.confirm_transaction(
          payment_request: payment_request,
          transaction_hash: transaction_hash
        )
      end
    end

    describe '.initiate_hosted_payment' do
      it 'sends request with correct parameters' do
        payment_params = {
          amount: 100,
          currency: 'usd',
          country_code: 'US',
          payment_type: 'BANK_TRANSFER',
          reference: 'ref123',
          redirect_url: 'https://example.com',
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com'
        }

        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'initiateHostedPaymnet',
          query: CashrampSDKRuby::Client::Mutations::INITIATE_HOSTED_PAYMENT,
          variables: {
            amount: payment_params[:amount],
            currency: payment_params[:currency],
            countryCode: payment_params[:country_code],
            paymentType: payment_params[:payment_type],
            reference: payment_params[:reference],
            redirect_url: payment_params[:redirect_url],
            firstName: payment_params[:first_name],
            lastName: payment_params[:last_name],
            email: payment_params[:email]
          }
        )
        
        CashrampSDKRuby::Client.initiate_hosted_payment(payment_params)
      end
    end

    describe '.cancel_hosted_payment' do
      it 'sends request with correct parameters' do
        payment_request = { id: 'pr123' }
        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'cancelHostedPayment',
          query: CashrampSDKRuby::Client::Mutations::CANCEL_HOSTED_PAYMENT,
          variables: payment_request
        )
        
        CashrampSDKRuby::Client.cancel_hosted_payment(payment_request)
      end
    end

    describe '.create_customer' do
      it 'sends request with correct parameters' do
        customer_details = {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          country: 'US'
        }

        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'createCustomer',
          query: CashrampSDKRuby::Client::Mutations::CREATE_CUSTOMER,
          variables: customer_details
        )
        
        CashrampSDKRuby::Client.create_customer(customer_details)
      end
    end

    describe '.add_payment_method' do
      it 'sends request with correct parameters' do
        payment_method_options = {
          customer: 'cust123',
          p2p_payment_method_type: 'bank_transfer',
          fields: [{ name: 'account_number', value: '123456' }]
        }

        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'addPaymentMethod',
          query: CashrampSDKRuby::Client::Mutations::ADD_PAYMENT_METHOD,
          variables: payment_method_options
        )
        
        CashrampSDKRuby::Client.add_payment_method(payment_method_options)
      end
    end

    describe '.withdraw_onchain' do
      it 'sends request with correct parameters' do
        withdraw_options = {
          address: '0x123...',
          amount_usd: 100
        }

        expect(CashrampSDKRuby::Client).to receive(:send_request).with(
          name: 'withdrawOnchain',
          query: CashrampSDKRuby::Client::Mutations::WITHDRAW_ONCHAIN,
          variables: withdraw_options
        )
        
        CashrampSDKRuby::Client.withdraw_onchain(withdraw_options)
      end
    end
  end
end 