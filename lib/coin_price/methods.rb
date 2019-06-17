module CoinPrice
  class << self
    def cache_key
      "#{config.cache_key_prefix}coin_price"
    end

    def redis
      @redis_url ||= config.redis_url
      @redis ||= Redis.new(url: @redis_url)

      @redis_url != config.redis_url ? redis_reset : @redis
    end

    def redis_reset
      @redis_url = config.redis_url
      @redis = Redis.new(url: @redis_url)
    end

    def latest(base = 'BTC', quote = 'USD', source = 'coinmarketcap', options = { from_cache: false })
      case source
      when 'coinmarketcap'
        CoinMarketCap::Latest.call(base, quote, options)
      else
        raise UnknownSourceError, source
      end
    end

    def listings(bases = ['BTC'], quotes = ['USD'], source = 'coinmarketcap', options = { from_cache: false })
      case source
      when 'coinmarketcap'
        CoinMarketCap::Listings.call(bases, quotes, options)
      else
        raise UnknownSourceError, source
      end
    end

    def requests_count(source = 'coinmarketcap')
      case source
      when 'coinmarketcap'
        CoinMarketCap::API.requests_count
      else
        raise UnknownSourceError, source
      end
    end
  end
end
