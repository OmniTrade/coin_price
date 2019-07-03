module CoinPrice
  class << self
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
end
