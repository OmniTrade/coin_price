module CoinPrice
  module CoinMarketCap
    class Listings
      attr_accessor :bases, :quotes, :options

      def initialize(bases = ['BTC'], quotes = ['USD'], options = { from_cache: false })
        @bases = bases.map { |base|  base.to_s.upcase }
        @quotes = quotes.map { |quote| quote.to_s.upcase }
        @options = options || {}
      end

      def self.call(bases = ['BTC'], quotes = ['USD'], options = { from_cache: false })
        new(bases, quotes, options).values
      end

      def values
        if options[:from_cache]
          read_cached_values
        else
          request_new_values
        end
      end

      def values=(values)
        values.each do |base, quotes|
          quotes.each do |quote, value|
            Latest.new(base, quote).value = value
          end
        end
      end

      def timestamps
        timestamps = {}
        bases.each do |base|
          timestamps[base] = {}
          quotes.each do |quote|
            timestamps[base][quote] = Latest.new(base, quote).timestamp
          end
        end
        timestamps
      end

      def timestamps=(timestamp)
        bases.each do |base|
          quotes.each do |quote|
            Latest.new(base, quote).timestamp = timestamp
          end
        end
      end

      def api_endpoint_listings
        "#{API.endpoint}/cryptocurrency/listings/latest"
      end

      def url(quote, limit = CoinPrice.config.listings_limit)
        convert = API.code_id(quote) ? "convert_id=#{API.code_id(quote)}" : "convert=#{quote}"
        limit = "limit=#{limit}" # maximum limit is 5_000

        "#{api_endpoint_listings}?#{convert}&#{limit}"
      end

      private

      def read_cached_values
        values = {}
        bases.each do |base|
          values[base] = {}
          quotes.each do |quote|
            values[base][quote] = Latest.new(base, quote, from_cache: true).value
          end
        end
        values
      end

      def request_new_values
        self.timestamps = Time.now.to_i
        self.values = results_from_request
      end

      def results_from_request
        responses = requests_foreach_quote

        values = {}
        bases.each do |base|
          values[base] = {}
          quotes.each do |quote|
            values[base][quote] = find_value(base, quote, responses)
          end
        end
        values
      end

      def requests_foreach_quote
        responses = {}
        quotes.each do |quote|
          sleep options[:wait].to_i
          responses[quote] = API.request(url(quote))
        end
        responses
      end

      def find_value(base, quote, responses)
        currency = find_coin(base, quote, responses)

        currency.dig('quote', quote, 'price')&.to_d ||
          currency.dig('quote', API.code_id(quote).to_s, 'price')&.to_d ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end

      def find_coin(base, quote, responses)
        responses[quote]&.dig('data')&.find { |item| item&.dig('id') == API.code_id(base) } ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end
    end
  end
end
