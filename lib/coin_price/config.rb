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
    attr_accessor :redis_enabled,
                  :redis_url,
                  :cache_key_prefix,
                  :default_source

    def initialize
      @redis_enabled = false
      @redis_url = 'redis://localhost:6379/0'
      @cache_key_prefix = ''
      @default_source = 'coinmarketcap'
    end
  end
end
