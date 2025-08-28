require 'logger'
require "wowza/api/version"
require "wowza/api/base"
require "wowza/api/transcoder"
require "wowza/api/recording"
require "wowza/api/vod_stream"
require "wowza/api/stream_target/base"
require "wowza/api/stream_target/akamai"
require "wowza/api/stream_target/fastly"
require "wowza/api/stream_target/custom"
require "wowza/api/stream_target/facebook"
require 'wowza/api/output'
require 'wowza/api/output_list'
require 'wowza/api/stream_target_list'
require 'wowza/api/configuration'

module Wowza
  module Api
    class << self
      attr_writer :configuration
    end

    def self.configuration
      @configuration ||= Wowza::Api::Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    class Error < StandardError; end

  end
end
