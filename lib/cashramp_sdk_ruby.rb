# frozen_string_literal: true
require 'httparty'
require_relative "cashramp_sdk_ruby/client"
require_relative "cashramp_sdk_ruby/queries"
require_relative "cashramp_sdk_ruby/mutations"

module CashrampSDKRuby
  class Error < StandardError
    # Your code goes here...
  end
end
