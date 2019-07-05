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
        fetch_values
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
      bases.product(quotes).each_with_object({}) do |pair, result|
        base, quote = pair
        result[base] ||= {}
        result[base][quote] = CoinPrice.cache.get(cache_key_timestamp(base, quote)).to_i
      end
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
      bases.product(quotes).each_with_object({}) do |pair, result|
        base, quote = pair
        result[base] ||= {}
        result[base][quote] = \
          CoinPrice.cache.get(cache_key_value(base, quote))&.to_d ||
          (raise CoinPrice::CacheError, "#{base}/#{quote}: #{cache_key_value(base, quote)}")
      end
    end

    def fetch_values
      source.values(bases, quotes).tap do |new_values|
        self.values = new_values
        self.timestamps = Time.now.to_i
      end
    end
  end
end
