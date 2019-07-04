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
                  :default_source,
                  :wait_between_requests,
                  :max_request_retries

    def initialize
      @redis_url = 'redis://localhost:6379/0'
      @cache_key_prefix = ''
      @default_source = 'coinmarketcap'
      @wait_between_requests = 1 # seconds
      @max_request_retries = 3
    end
  end
end
