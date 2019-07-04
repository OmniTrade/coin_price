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

  class Cache
    attr_reader :local

    def initialize
      @mutex = Mutex.new
      @local = {}
    end

    def get(key)
      if CoinPrice.config.redis_enabled
        CoinPrice.redis.get(key)
      else
        @mutex.synchronize do
          @local[key.to_s]
        end
      end
    end

    def set(key, value)
      if CoinPrice.config.redis_enabled
        CoinPrice.redis.set(key, value)
      else
        @mutex.synchronize do
          @local[key.to_s] = value.to_s
        end
      end
    end

    def incrby(key, number)
      if CoinPrice.config.redis_enabled
        CoinPrice.redis.incrby(key, number)
      else
        @mutex.synchronize do
          @local[key.to_s] = (@local[key.to_s].to_i + number.to_i).to_s
        end
      end
    end
  end
end
