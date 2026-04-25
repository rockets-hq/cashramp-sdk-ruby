require 'spec_helper'

RSpec.describe Cashramp::Client do
  describe 'configuration' do
    it 'initializes with test environment' do
      Cashramp::Client.initialize(env: :test, secret_key: 'test_key')
      expect(Cashramp::Client.env).to eq(:test)
      expect(Cashramp::Client.secret_key).to eq('test_key')
    end

    it 'raises error with invalid environment' do
      expect {
        Cashramp::Client.initialize(env: :invalid, secret_key: 'test_key')
      }.to raise_error(ArgumentError, 'Invalid environment')
    end

    it 'raises error without secret key' do
      expect {
        Cashramp::Client.initialize(env: :test, secret_key: nil)
      }.to raise_error(ArgumentError, 'Please provide your API secret key.')
    end
  end

  describe 'API requests' do
    before(:all) do
      Cashramp::Client.initialize(env: :test, secret_key: 'test_key')
    end

    describe '.send_request' do
      let(:query) { 'query { test }' }
      let(:name) { 'test' }

      before do
        stub_request(:post, "https://staging.api.useaccrue.com/cashramp/api/graphql")
          .with(
            body: { query: query, variables: {} }.to_json,
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
          result = Cashramp::Client.send_request(name: name, query: query)
          expect(result.success?).to be true
          expect(result.result).to eq('result')
          expect(result.error).to be_nil
        end
      end

      context 'when the request returns GraphQL errors' do
        let(:status_code) { 200 }
        let(:response_body) do
          { data: nil, errors: [{ message: 'GraphQL Error' }] }.to_json
        end

        it 'returns a failure response with error message' do
          result = Cashramp::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
          expect(result.error).to eq('GraphQL Error')
        end
      end

      context 'when the request fails with HTTP error' do
        let(:status_code) { 400 }
        let(:response_body) { 'Bad Request' }

        it 'returns a failure response' do
          result = Cashramp::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
        end
      end

      context 'when HTTParty raises an error' do
        let(:status_code) { 400 }
        let(:response_body) { 'Bad Request' }

        before do
          allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new('Network error'))
        end

        it 'returns a failure response with the error message' do
          result = Cashramp::Client.send_request(name: name, query: query)
          expect(result.success?).to be false
          expect(result.error).to eq('Network error')
        end
      end
    end

    describe 'queries' do
      describe '.available_countries' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'availableCountries',
            query: Cashramp::Client::Queries::AVAILABLE_COUNTRIES,
          )

          Cashramp::Client.available_countries
        end
      end

      describe '.market_rate' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'marketRate',
            query: Cashramp::Client::Queries::MARKET_RATE,
            variables: { countryCode: 'NG' },
          )

          Cashramp::Client.market_rate(country_code: 'NG')
        end
      end

      describe '.payment_method_types' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'p2pPaymentMethodTypes',
            query: Cashramp::Client::Queries::PAYMENT_METHOD_TYPES,
            variables: { country: 'country_id' },
          )

          Cashramp::Client.payment_method_types(country: 'country_id')
        end
      end

      describe '.rampable_assets' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'rampableAssets',
            query: Cashramp::Client::Queries::RAMPABLE_ASSETS,
          )

          Cashramp::Client.rampable_assets
        end
      end

      describe '.ramp_limits' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'rampLimits',
            query: Cashramp::Client::Queries::RAMP_LIMITS,
          )

          Cashramp::Client.ramp_limits
        end
      end

      describe '.payment_request' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'merchantPaymentRequest',
            query: Cashramp::Client::Queries::PAYMENT_REQUEST,
            variables: { reference: 'ref123' },
          )

          Cashramp::Client.payment_request(reference: 'ref123')
        end
      end

      describe '.account' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'account',
            query: Cashramp::Client::Queries::ACCOUNT,
          )

          Cashramp::Client.account
        end
      end
    end

    describe 'mutations' do
      describe '.confirm_transaction' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'confirmTransaction',
            query: Cashramp::Client::Mutations::CONFIRM_TRANSACTION,
            variables: { paymentRequest: 'pr123', transactionHash: 'tx456' },
          )

          Cashramp::Client.confirm_transaction(payment_request: 'pr123', transaction_hash: 'tx456')
        end
      end

      describe '.initiate_hosted_payment' do
        let(:base_params) do
          {
            amount: 100,
            country_code: 'GH',
            payment_type: 'deposit',
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com',
          }
        end

        it 'forwards required fields and defaults currency to "usd"' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'initiateHostedPayment',
            query: Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT,
            variables: {
              amount: 100,
              currency: 'usd',
              countryCode: 'GH',
              paymentType: 'deposit',
              firstName: 'John',
              lastName: 'Doe',
              email: 'john@example.com',
            },
          )

          Cashramp::Client.initiate_hosted_payment(**base_params)
        end

        it 'forwards optional reference, redirect_url, metadata using camelCase keys' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'initiateHostedPayment',
            query: Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT,
            variables: {
              amount: 100,
              currency: 'local_currency',
              countryCode: 'GH',
              paymentType: 'deposit',
              reference: 'ref_123',
              redirectUrl: 'https://example.com/cb',
              metadata: { order_id: 'order_123' },
              firstName: 'John',
              lastName: 'Doe',
              email: 'john@example.com',
            },
          )

          Cashramp::Client.initiate_hosted_payment(
            **base_params,
            currency: 'local_currency',
            reference: 'ref_123',
            redirect_url: 'https://example.com/cb',
            metadata: { order_id: 'order_123' },
          )
        end

        it 'sends metadata: $metadata in the GraphQL mutation string' do
          expect(Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT).to include('$metadata: JSON')
          expect(Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT).to include('metadata: $metadata')
          expect(Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT).to include('redirectUrl: $redirectUrl')
        end
      end

      describe '.cancel_hosted_payment' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'cancelHostedPayment',
            query: Cashramp::Client::Mutations::CANCEL_HOSTED_PAYMENT,
            variables: { paymentRequest: 'pr123' },
          )

          Cashramp::Client.cancel_hosted_payment(payment_request_id: 'pr123')
        end
      end

      describe '.create_customer' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'createCustomer',
            query: Cashramp::Client::Mutations::CREATE_CUSTOMER,
            variables: {
              firstName: 'John',
              lastName: 'Doe',
              email: 'john@example.com',
              country: 'country_id',
            },
          )

          Cashramp::Client.create_customer(
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com',
            country: 'country_id',
          )
        end
      end

      describe '.add_payment_method' do
        let(:fields) { [{ identifier: 'account_number', value: '1234567890' }] }

        it 'sends without ownership when omitted' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'addPaymentMethod',
            query: Cashramp::Client::Mutations::ADD_PAYMENT_METHOD,
            variables: {
              customer: 'cust123',
              paymentMethodType: 'bank_transfer',
              fields: fields,
            },
          )

          Cashramp::Client.add_payment_method(
            customer: 'cust123',
            payment_method_type: 'bank_transfer',
            fields: fields,
          )
        end

        it 'forwards ownership when provided' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'addPaymentMethod',
            query: Cashramp::Client::Mutations::ADD_PAYMENT_METHOD,
            variables: {
              customer: 'cust123',
              paymentMethodType: 'bank_transfer',
              fields: fields,
              ownership: 'third_party',
            },
          )

          Cashramp::Client.add_payment_method(
            customer: 'cust123',
            payment_method_type: 'bank_transfer',
            fields: fields,
            ownership: 'third_party',
          )
        end

        it 'declares the GraphQL paymentMethodType variable as String! and passes it correctly' do
          expect(Cashramp::Client::Mutations::ADD_PAYMENT_METHOD).to include('$paymentMethodType: String!')
          expect(Cashramp::Client::Mutations::ADD_PAYMENT_METHOD).to include('paymentMethodType: $paymentMethodType')
          expect(Cashramp::Client::Mutations::ADD_PAYMENT_METHOD).not_to include('p2pPaymentMethodType:')
          expect(Cashramp::Client::Mutations::ADD_PAYMENT_METHOD).to include('$ownership: P2PPaymentMethodOwnership')
        end
      end

      describe '.withdraw_onchain' do
        it 'sends only the supplied variables, compacting nils' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'withdrawOnchain',
            query: Cashramp::Client::Mutations::WITHDRAW_ONCHAIN,
            variables: { address: '0x123', amountUsd: 100 },
          )

          Cashramp::Client.withdraw_onchain(address: '0x123', amount_usd: 100)
        end

        it 'forwards optional network and metadata' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'withdrawOnchain',
            query: Cashramp::Client::Mutations::WITHDRAW_ONCHAIN,
            variables: {
              address: '0x123',
              amountUsd: 100,
              network: 'celo',
              metadata: { reference: 'xyz' },
            },
          )

          Cashramp::Client.withdraw_onchain(
            address: '0x123',
            amount_usd: 100,
            network: 'celo',
            metadata: { reference: 'xyz' },
          )
        end
      end
    end

    describe 'Direct Ramp' do
      describe '.ramp_quote' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'rampQuote',
            query: Cashramp::Client::Queries::RAMP_QUOTE,
            variables: {
              customer: 'customer_id',
              amount: 100.0,
              currency: 'usd',
              paymentType: 'withdrawal',
              paymentMethodType: 'bank_transfer_ng',
              country: 'NG',
            },
          )

          Cashramp::Client.ramp_quote(
            customer: 'customer_id',
            amount: 100.0,
            currency: 'usd',
            payment_type: 'withdrawal',
            payment_method_type: 'bank_transfer_ng',
            country: 'NG',
          )
        end

        it 'defaults payment_type to "deposit" when omitted' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'rampQuote',
            query: Cashramp::Client::Queries::RAMP_QUOTE,
            variables: {
              customer: 'customer_id',
              amount: 100.0,
              currency: 'usd',
              paymentType: 'deposit',
              paymentMethodType: 'mtn_momo_gh',
            },
          )

          Cashramp::Client.ramp_quote(
            customer: 'customer_id',
            amount: 100.0,
            currency: 'usd',
            payment_method_type: 'mtn_momo_gh',
          )
        end

        it 'declares $paymentType as optional in the GraphQL query' do
          expect(Cashramp::Client::Queries::RAMP_QUOTE).to include('$paymentType: PaymentTypeType,')
          expect(Cashramp::Client::Queries::RAMP_QUOTE).not_to include('$paymentType: PaymentTypeType!')
        end
      end

      describe '.refresh_ramp_quote' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'refreshRampQuote',
            query: Cashramp::Client::Queries::REFRESH_RAMP_QUOTE,
            variables: { rampQuote: 'quote_id', amount: 150.0 },
          )

          Cashramp::Client.refresh_ramp_quote(ramp_quote_id: 'quote_id', amount: 150.0)
        end
      end

      describe '.initiate_ramp_quote_deposit' do
        it 'forwards rampQuote and other variables, compacting nils' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'initiateRampQuoteDeposit',
            query: Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
            variables: {
              rampQuote: 'quote_id',
              reference: 'ref_123',
              phoneNumber: '+234123456789',
            },
          )

          Cashramp::Client.initiate_ramp_quote_deposit(
            ramp_quote_id: 'quote_id',
            reference: 'ref_123',
            phone_number: '+234123456789',
          )
        end

        it 'forwards onchain_transfer_info as $onchainTransferInfo (camelCase)' do
          info = {
            address: '0x1234567890abcdef1234567890abcdef12345678',
            cryptocurrency: 'usd_tether',
            network: 'celo',
          }

          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'initiateRampQuoteDeposit',
            query: Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
            variables: {
              rampQuote: 'quote_id',
              reference: 'ref_123',
              onchainTransferInfo: info,
            },
          )

          Cashramp::Client.initiate_ramp_quote_deposit(
            ramp_quote_id: 'quote_id',
            reference: 'ref_123',
            onchain_transfer_info: info,
          )
        end

        it 'declares $onchainTransferInfo: OnchainTransferInfo in the mutation' do
          expect(Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_DEPOSIT)
            .to include('$onchainTransferInfo: OnchainTransferInfo')
          expect(Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_DEPOSIT)
            .to include('onchainTransferInfo: $onchainTransferInfo')
        end
      end

      describe '.mark_deposit_as_paid' do
        it 'forwards receipt when provided' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'markDepositAsPaid',
            query: Cashramp::Client::Mutations::MARK_DEPOSIT_AS_PAID,
            variables: { paymentRequest: 'payment_123', receipt: 'https://example.com/receipt.png' },
          )

          Cashramp::Client.mark_deposit_as_paid(
            payment_request_id: 'payment_123',
            receipt: 'https://example.com/receipt.png',
          )
        end

        it 'compacts nil receipt' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'markDepositAsPaid',
            query: Cashramp::Client::Mutations::MARK_DEPOSIT_AS_PAID,
            variables: { paymentRequest: 'payment_123' },
          )

          Cashramp::Client.mark_deposit_as_paid(payment_request_id: 'payment_123')
        end
      end

      describe '.cancel_deposit' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'cancelDeposit',
            query: Cashramp::Client::Mutations::CANCEL_DEPOSIT,
            variables: { paymentRequest: 'payment_123' },
          )

          Cashramp::Client.cancel_deposit(payment_request_id: 'payment_123')
        end
      end

      describe '.initiate_ramp_quote_withdrawal' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'initiateRampQuoteWithdrawal',
            query: Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_WITHDRAWAL,
            variables: {
              rampQuote: 'quote_id',
              paymentMethod: 'payment_method_123',
              reference: 'ref_456',
            },
          )

          Cashramp::Client.initiate_ramp_quote_withdrawal(
            ramp_quote_id: 'quote_id',
            payment_method_id: 'payment_method_123',
            reference: 'ref_456',
          )
        end
      end

      describe '.mark_withdrawal_as_received' do
        it 'sends request with correct parameters' do
          expect(Cashramp::Client).to receive(:send_request).with(
            name: 'markWithdrawalAsReceived',
            query: Cashramp::Client::Mutations::MARK_WITHDRAWAL_AS_RECEIVED,
            variables: { paymentRequest: 'payment_456' },
          )

          Cashramp::Client.mark_withdrawal_as_received(payment_request_id: 'payment_456')
        end
      end
    end
  end

  describe 'wire-level GraphQL payloads' do
    before(:all) do
      Cashramp::Client.initialize(env: :test, secret_key: 'test_key')
    end

    let(:endpoint) { 'https://staging.api.useaccrue.com/cashramp/api/graphql' }

    it 'sends initiate_hosted_payment with redirectUrl (camelCase) and metadata' do
      expected_body = {
        query: Cashramp::Client::Mutations::INITIATE_HOSTED_PAYMENT,
        variables: {
          amount: 100,
          currency: 'usd',
          countryCode: 'GH',
          paymentType: 'deposit',
          reference: 'order_123',
          redirectUrl: 'https://example.com/cb',
          metadata: { order_id: 'order_123' },
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
        },
      }.to_json

      stub_request(:post, endpoint)
        .with(body: expected_body)
        .to_return(status: 200, body: { data: { initiateHostedPayment: { id: 'p_1' } } }.to_json)

      response = Cashramp::Client.initiate_hosted_payment(
        amount: 100,
        country_code: 'GH',
        payment_type: 'deposit',
        reference: 'order_123',
        redirect_url: 'https://example.com/cb',
        metadata: { order_id: 'order_123' },
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
      )

      expect(response.success?).to be true
      expect(response.result).to eq({ 'id' => 'p_1' })
    end

    it 'sends add_payment_method with paymentMethodType (not p2pPaymentMethodType)' do
      fields = [{ identifier: 'account_number', value: '1234567890' }]
      expected_body = {
        query: Cashramp::Client::Mutations::ADD_PAYMENT_METHOD,
        variables: {
          customer: 'cust_1',
          paymentMethodType: 'bank_transfer',
          fields: fields,
          ownership: 'first_party',
        },
      }.to_json

      stub_request(:post, endpoint)
        .with(body: expected_body)
        .to_return(status: 200, body: { data: { addPaymentMethod: { id: 'pm_1' } } }.to_json)

      response = Cashramp::Client.add_payment_method(
        customer: 'cust_1',
        payment_method_type: 'bank_transfer',
        fields: fields,
        ownership: 'first_party',
      )

      expect(response.success?).to be true
    end

    it 'sends initiate_ramp_quote_deposit with onchainTransferInfo' do
      info = {
        address: '0xabc',
        cryptocurrency: 'usd_tether',
        network: 'celo',
      }
      expected_body = {
        query: Cashramp::Client::Mutations::INITIATE_RAMP_QUOTE_DEPOSIT,
        variables: {
          rampQuote: 'quote_1',
          onchainTransferInfo: info,
        },
      }.to_json

      stub_request(:post, endpoint)
        .with(body: expected_body)
        .to_return(status: 200, body: { data: { initiateRampQuoteDeposit: { id: 'd_1' } } }.to_json)

      response = Cashramp::Client.initiate_ramp_quote_deposit(
        ramp_quote_id: 'quote_1',
        onchain_transfer_info: info,
      )

      expect(response.success?).to be true
    end
  end
end
