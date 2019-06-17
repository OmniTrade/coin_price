module CoinPrice
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
    attr_accessor :redis_url,
                  :cache_key_prefix,
                  :max_request_retries,
                  :refresher_wait,
                  :refresher_wait_weekday_multiplier,
                  :refresher_wait_weekend_multiplier,
                  :coinmarketcap_api_key

    def initialize
      @redis_url = 'redis://localhost:6379/0'
      @cache_key_prefix = ''
      @max_request_retries = 3
      @refresher_wait = 60 # seconds
      @refresher_wait_weekday_multiplier = 1
      @refresher_wait_weekend_multiplier = 1
      @coinmarketcap_api_key = nil
    end
  end
end
