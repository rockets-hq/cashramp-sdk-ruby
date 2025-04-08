# frozen_string_literal: true

RSpec.describe CashrampSDKRuby do
  it "has a version number" do
    expect(CashrampSDKRuby::VERSION).not_to be nil
  end

  it "can be configured" do
    CashrampSDKRuby::Client.initialize(env: :test, secret_key: 'test_key')
    expect(CashrampSDKRuby::Client.env).to eq(:test)
  end
end
