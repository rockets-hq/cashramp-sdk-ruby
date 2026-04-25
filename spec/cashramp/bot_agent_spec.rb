require 'spec_helper'

RSpec.describe Cashramp::Client, '#bot agent surface' do
  let(:bot_endpoint) { 'https://staging.api.useaccrue.com/cashramp/bot/graphql' }
  let(:merchant_endpoint) { 'https://staging.api.useaccrue.com/cashramp/api/graphql' }

  before(:all) do
    Cashramp::Client.initialize(env: :test, secret_key: 'test_key')
  end

  describe 'endpoint configuration' do
    it 'tracks both merchant and bot endpoint URLs' do
      expect(Cashramp::Client.instance_variable_get(:@endpoint)).to eq(merchant_endpoint)
      expect(Cashramp::Client.instance_variable_get(:@bot_endpoint)).to eq(bot_endpoint)
    end
  end

  describe '.send_request endpoint routing' do
    it 'routes endpoint: :bot calls to the bot endpoint' do
      stub_request(:post, bot_endpoint)
        .to_return(status: 200, body: { data: { profile: { 'id' => 'a_1' } } }.to_json)

      result = Cashramp::Client.send_request(
        name: 'profile',
        query: 'query { profile { id } }',
        endpoint: :bot,
      )
      expect(result.success?).to be true
      expect(WebMock).to have_requested(:post, bot_endpoint)
    end

    it 'still routes to the merchant endpoint by default' do
      stub_request(:post, merchant_endpoint)
        .to_return(status: 200, body: { data: { account: { 'id' => 'm_1' } } }.to_json)

      Cashramp::Client.send_request(name: 'account', query: 'query { account { id } }')
      expect(WebMock).to have_requested(:post, merchant_endpoint)
    end
  end

  describe '.bot_agent_profile' do
    it 'sends request to the bot endpoint with correct parameters' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'profile',
        query: Cashramp::Client::Queries::BOT_AGENT_PROFILE,
        endpoint: :bot,
      )

      Cashramp::Client.bot_agent_profile
    end
  end

  describe '.bot_agent_order_history' do
    it 'forwards page/per_page/filter, compacting nils, with bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'orderHistory',
        query: Cashramp::Client::Queries::BOT_AGENT_ORDER_HISTORY,
        variables: { page: 2, perPage: 20, filter: { status: 'completed' } },
        endpoint: :bot,
      )

      Cashramp::Client.bot_agent_order_history(
        page: 2,
        per_page: 20,
        filter: { status: 'completed' },
      )
    end

    it 'sends only page when per_page and filter are omitted' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'orderHistory',
        query: Cashramp::Client::Queries::BOT_AGENT_ORDER_HISTORY,
        variables: { page: 1 },
        endpoint: :bot,
      )

      Cashramp::Client.bot_agent_order_history(page: 1)
    end
  end

  describe '.bot_agent_withdrawal_info' do
    it 'sends symbol with bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'withdrawalInfo',
        query: Cashramp::Client::Queries::BOT_AGENT_WITHDRAWAL_INFO,
        variables: { symbol: 'USDC' },
        endpoint: :bot,
      )

      Cashramp::Client.bot_agent_withdrawal_info(symbol: 'USDC')
    end
  end

  describe '.accept_bot_agent_withdrawal' do
    it 'maps payment_request_id to p2pPayment and uses bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'acceptWithdrawal',
        query: Cashramp::Client::Mutations::BOT_AGENT_ACCEPT_WITHDRAWAL,
        variables: { p2pPayment: 'p2p_1' },
        endpoint: :bot,
      )

      Cashramp::Client.accept_bot_agent_withdrawal(payment_request_id: 'p2p_1')
    end
  end

  describe '.cancel_bot_agent_withdrawal' do
    it 'maps payment_request_id to p2pPayment and uses bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'cancelWithdrawal',
        query: Cashramp::Client::Mutations::BOT_AGENT_CANCEL_WITHDRAWAL,
        variables: { p2pPayment: 'p2p_1' },
        endpoint: :bot,
      )

      Cashramp::Client.cancel_bot_agent_withdrawal(payment_request_id: 'p2p_1')
    end
  end

  describe '.mark_bot_agent_deposit_received' do
    it 'maps payment_request_id to p2pPayment and uses bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'markDepositAsReceived',
        query: Cashramp::Client::Mutations::BOT_AGENT_MARK_DEPOSIT_AS_RECEIVED,
        variables: { p2pPayment: 'p2p_1' },
        endpoint: :bot,
      )

      Cashramp::Client.mark_bot_agent_deposit_received(payment_request_id: 'p2p_1')
    end
  end

  describe '.mark_bot_agent_withdrawal_paid' do
    it 'forwards p2pPayment, paymentMethod, and optional receipt' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'markWithdrawalAsPaid',
        query: Cashramp::Client::Mutations::BOT_AGENT_MARK_WITHDRAWAL_AS_PAID,
        variables: {
          p2pPayment: 'p2p_1',
          paymentMethod: 'pm_1',
          receipt: 'https://example.com/receipt.png',
        },
        endpoint: :bot,
      )

      Cashramp::Client.mark_bot_agent_withdrawal_paid(
        payment_request_id: 'p2p_1',
        payment_method_id: 'pm_1',
        receipt: 'https://example.com/receipt.png',
      )
    end

    it 'compacts nil receipt' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'markWithdrawalAsPaid',
        query: Cashramp::Client::Mutations::BOT_AGENT_MARK_WITHDRAWAL_AS_PAID,
        variables: {
          p2pPayment: 'p2p_1',
          paymentMethod: 'pm_1',
        },
        endpoint: :bot,
      )

      Cashramp::Client.mark_bot_agent_withdrawal_paid(
        payment_request_id: 'p2p_1',
        payment_method_id: 'pm_1',
      )
    end
  end

  describe '.update_bot_agent_rates' do
    it 'forwards only provided fields and uses bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'updateRates',
        query: Cashramp::Client::Mutations::BOT_AGENT_UPDATE_RATES,
        variables: { depositRate: 1500, withdrawalMargin: '0.01' },
        endpoint: :bot,
      )

      Cashramp::Client.update_bot_agent_rates(
        deposit_rate: 1500,
        withdrawal_margin: '0.01',
      )
    end
  end

  describe '.update_bot_agent_payment_method_liquidity' do
    it 'forwards amount_local + payment_method_id with bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'updatePaymentMethodLiquidity',
        query: Cashramp::Client::Mutations::BOT_AGENT_UPDATE_PAYMENT_METHOD_LIQUIDITY,
        variables: { amountLocal: 5000, paymentMethod: 'pm_1' },
        endpoint: :bot,
      )

      Cashramp::Client.update_bot_agent_payment_method_liquidity(
        amount_local: 5000,
        payment_method_id: 'pm_1',
      )
    end

    it 'forwards amount_local + payment_method_type with bot endpoint' do
      expect(Cashramp::Client).to receive(:send_request).with(
        name: 'updatePaymentMethodLiquidity',
        query: Cashramp::Client::Mutations::BOT_AGENT_UPDATE_PAYMENT_METHOD_LIQUIDITY,
        variables: { amountLocal: 5000, paymentMethodType: 'bank_transfer_ng' },
        endpoint: :bot,
      )

      Cashramp::Client.update_bot_agent_payment_method_liquidity(
        amount_local: 5000,
        payment_method_type: 'bank_transfer_ng',
      )
    end
  end

  describe 'wire-level GraphQL payloads' do
    it 'sends accept_bot_agent_withdrawal to the bot endpoint with mapped variables' do
      expected_body = {
        query: Cashramp::Client::Mutations::BOT_AGENT_ACCEPT_WITHDRAWAL,
        variables: { p2pPayment: 'p2p_1' },
      }.to_json

      stub_request(:post, bot_endpoint)
        .with(
          body: expected_body,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_key',
          },
        )
        .to_return(status: 200, body: { data: { acceptWithdrawal: true } }.to_json)

      response = Cashramp::Client.accept_bot_agent_withdrawal(payment_request_id: 'p2p_1')
      expect(response.success?).to be true
      expect(response.result).to eq(true)
    end

    it 'sends bot_agent_profile to the bot endpoint, NOT the merchant endpoint' do
      stub_request(:post, bot_endpoint)
        .to_return(status: 200, body: { data: { profile: { 'id' => 'a_1' } } }.to_json)

      response = Cashramp::Client.bot_agent_profile
      expect(response.success?).to be true
      expect(WebMock).to have_requested(:post, bot_endpoint)
      expect(WebMock).not_to have_requested(:post, merchant_endpoint)
    end
  end
end
