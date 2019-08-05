module CoinPrice
  class << self
    def cache
      @cache ||= Cache.new
    end

    def cache_reset
      @cache = Cache.new
    end

    # redis returns the Redis instance or reset it if @current_redis_url has been changed.
    def redis
      @current_redis_url ||= config.redis_url
      @redis ||= Redis.new(url: @current_redis_url)

      @current_redis_url != config.redis_url ? redis_reset : @redis
    end

    def redis_reset
      @current_redis_url = config.redis_url
      @redis = Redis.new(url: @current_redis_url)
    end
  end

  # Cache holds an in-memory hash where price values and timestamps are stored.
  # If CoinPrice.config.redis_enabled is true, then it uses Redis instead.
  class Cache
    attr_reader :local

    def initialize
      @mutex = Mutex.new
      @local = {}
    end

    def get(key)
      return CoinPrice.redis.get(key) if CoinPrice.config.redis_enabled

      @mutex.synchronize do
        @local[key.to_s]
      end
    end

    def set(key, value)
      return CoinPrice.redis.set(key, value) if CoinPrice.config.redis_enabled

      @mutex.synchronize do
        @local[key.to_s] = value.to_s
      end
    end

    def incrby(key, number)
      return CoinPrice.redis.incrby(key, number) if CoinPrice.config.redis_enabled

      @mutex.synchronize do
        @local[key.to_s] = (@local[key.to_s].to_i + number.to_i).to_s
      end
    end
  end
end
