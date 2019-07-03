module CoinPrice
  module Refresher
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
      attr_accessor :wait,
                    :wait_weekday_multiplier,
                    :wait_weekend_multiplier

      def initialize
        @wait = 120 # seconds
        @wait_weekday_multiplier = 1
        @wait_weekend_multiplier = 1
      end
    end
  end
end
