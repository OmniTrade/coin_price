module CoinPrice
  module Omnitrade
    class << self
      def config
        @config ||= Config.new
      end

      def config_reset
        @config = Config.new
      end

      def configure
        yield config
      end
    end

    class Config
      attr_accessor :wait_between_requests,
                    :max_request_retries

      def initialize
        @wait_between_requests = 1 # seconds
        @max_request_retries = 3
      end
    end
  end
end
