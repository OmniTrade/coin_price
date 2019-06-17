module CoinPrice
  module CoinMarketCap
    class Latest
      attr_accessor :base, :quote, :options

      def initialize(base = 'BTC', quote = 'USD', options = { from_cache: false })
        @base = base.to_s.upcase
        @quote = quote.to_s.upcase
        @options = options || {}
      end

      def self.call(base = 'BTC', quote = 'USD', options = { from_cache: false })
        new(base, quote, options).value
      end

      def value
        if options[:from_cache]
          read_cached_value
        else
          request_new_value
        end
      end

      def value=(value)
        CoinPrice.redis.set(cache_key_value, value)
      end

      def timestamp
        CoinPrice.redis.get(cache_key_timestamp).to_i || 0
      end

      def timestamp=(timestamp)
        CoinPrice.redis.set(cache_key_timestamp, timestamp)
      end

      def api_endpoint_latest
        "#{API.endpoint}/tools/price-conversion"
      end

      def url
        id = "id=#{API.code_id(base)}"
        convert = API.code_id(quote) ? "convert_id=#{API.code_id(quote)}" : "convert=#{quote}"
        amount = 'amount=1'

        "#{api_endpoint_latest}?#{id}&#{convert}&#{amount}"
      end

      def cache_key_timestamp
        "#{CacheKey.timestamp}:#{base}:#{quote}"
      end

      def cache_key_value
        "#{CacheKey.value}:#{base}:#{quote}"
      end

      private

      def read_cached_value
        CoinPrice.redis.get(cache_key_value)&.to_d ||
          (raise CoinPrice::CacheError, "#{base}/#{quote}: #{cache_key_value}")
      end

      def request_new_value
        self.timestamp = Time.now.to_i
        self.value = result_from_request
      end

      def result_from_request
        find_value(API.request(url))
      end

      def find_value(response)
        response.dig('data', 'quote', quote, 'price')&.to_d ||
          response.dig('data', 'quote', API.code_id(quote).to_s, 'price')&.to_d ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end
    end
  end
end
