# frozen_string_literal: true

RSpec.describe Cashramp do
  it "has a version number" do
    expect(Cashramp::VERSION).not_to be nil
  end

  it "can be configured" do
    Cashramp::Client.initialize(env: :test, secret_key: 'test_key')
    expect(Cashramp::Client.env).to eq(:test)
  end
end
