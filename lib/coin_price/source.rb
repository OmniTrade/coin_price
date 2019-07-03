module CoinPrice
  # Source is where we can fetch cryptocurrency latest prices from.
  # By inheriting this class, you must strictly implement methods `id` and `values`.
  class Source
    # id is a string that identifies a Source in the code.
    # You must register this id in `CoinPrice::AVAILABLE_SOURCES` along with
    # its class in order to use a Source via `CoinPrice` methods.
    def id
      raise NotImplementedError
    end

    # values returns a hash with the price for each base and quote currency pairs,
    # e.g.:
    #
    # values(['BTC', 'ETH', 'LTC'], ['USD', 'BTC'])
    #
    # => {
    #   "BTC" => {
    #     "USD" => 0.900291185472e4,
    #     "BTC" => 0.1e1
    #   },
    #   "ETH" => {
    #     "USD" => 0.268629998717e3,
    #     "BTC" => 0.298381238261445e-1
    #   },
    #   "LTC" => {
    #     "USD" => 0.136720443221e3,
    #     "BTC" => 0.15186247008441e-1
    #   }
    # }
    def values(_bases = ['BTC'], _quotes = ['USD'])
      raise NotImplementedError
    end

    # Optional attribute, not in use at the moment.
    def name
      ''
    end

    # Optional attribute, not in use at the moment.
    def website
      ''
    end

    def incr_requests_count(number = 1, date = Time.now.strftime('%Y-%m-%d'))
      CoinPrice.redis.incrby(cache_key_requests_count(date), number)
    end

    def requests_count(date = Time.now.strftime('%Y-%m-%d'))
      CoinPrice.redis.get(cache_key_requests_count(date))&.to_i || 0
    end

    # e.g.: "coin-price:your-source-id"
    def cache_key
      "#{CoinPrice.cache_key}:#{id}"
    end

    # e.g.: "coin-price:your-source-id:requests-count:2009-01-03"
    def cache_key_requests_count(date = Time.now.strftime('%Y-%m-%d'))
      "#{cache_key}:requests-count:#{date}"
    end
  end
end
