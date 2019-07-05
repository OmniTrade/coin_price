module CoinPrice
  module Coinpaprika
    class Source < CoinPrice::Source
      def id
        @id ||= 'coinpaprika'
      end

      def name
        @name ||= 'Coinpaprika'
      end

      def website
        @website ||= 'https://coinpaprika.com/'
      end

      def values(bases = ['BTC'], quotes = ['USD'])
        response = API.request(API.url_tickers(bases, quotes))
        incr_requests_count

        bases.product(quotes).each_with_object({}) do |pair, result|
          base, quote = pair
          data = bases.one? ? response : find_coin(base, quote, response)

          result[base] ||= {}
          result[base][quote] = find_value(base, quote, data)
        end
      end

      private

      def find_value(base, quote, data)
        data.dig('quotes', quote, 'price')&.to_d ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end

      def find_coin(base, quote, response)
        response.find { |item| item&.dig('id') == API::COIN_ID[base] } ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end
    end
  end
end
