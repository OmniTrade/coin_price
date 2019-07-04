module CoinPrice
  module CoinMarketCap
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
      attr_accessor :api_key,
                    :listings_limit,
                    :wait_between_requests,
                    :max_request_retries

      def initialize
        @api_key = nil
        @listings_limit = 200 # maximum limit is 5_000
        @wait_between_requests = 1 # seconds
        @max_request_retries = 3
      end
    end
  end
end
