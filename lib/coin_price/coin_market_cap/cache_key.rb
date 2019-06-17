module CoinPrice
  module CoinMarketCap
    class CacheKey
      class << self
        def to_s
          "#{CoinPrice.cache_key}:coinmarketcap"
        end

        def requests_count
          "#{CacheKey}:requests-count"
        end

        def value
          "#{CacheKey}:value"
        end

        def timestamp
          "#{CacheKey}:timestamp"
        end
      end
    end
  end
end
