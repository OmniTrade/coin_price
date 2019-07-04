module CoinPrice
  class Fetch
    attr_reader :bases, :quotes, :source, :options

    def initialize(bases, quotes, source, options = { from_cache: false })
      @bases = bases.map { |base| base.to_s.upcase }
      @quotes = quotes.map { |quote| quote.to_s.upcase }
      @source = source.new # klass
      @options = options || {}
    end

    def values
      if options[:from_cache]
        read_cached_values
      else
        fetched_values = source.values(bases, quotes)

        self.values = fetched_values
        self.timestamps = Time.now.to_i

        fetched_values
      end
    end

    def values=(new_values)
      new_values.each do |base, quotes|
        quotes.each do |quote, value|
          CoinPrice.cache.set(cache_key_value(base, quote), value)
        end
      end
    end

    def timestamps
      result = {}
      bases.each do |base|
        result[base] = {}
        quotes.each do |quote|
          result[base][quote] = CoinPrice.cache.get(cache_key_timestamp(base, quote)).to_i || 0
        end
      end
      result
    end

    def timestamps=(new_timestamp)
      bases.each do |base|
        quotes.each do |quote|
          CoinPrice.cache.set(cache_key_timestamp(base, quote), new_timestamp)
        end
      end
    end

    def cache_key_value(base, quote)
      "#{source.cache_key}:value:#{base}:#{quote}"
    end

    def cache_key_timestamp(base, quote)
      "#{source.cache_key}:timestamp:#{base}:#{quote}"
    end

    def read_cached_values
      result = {}
      bases.each do |base|
        result[base] = {}
        quotes.each do |quote|
          result[base][quote] = \
            CoinPrice.cache.get(cache_key_value(base, quote))&.to_d ||
            (raise CoinPrice::CacheError, "#{base}/#{quote}: #{cache_key_value(base, quote)}")
        end
      end
      result
    end
  end
end
