module CoinPrice
  module Omnitrade
    class Source < CoinPrice::Source
      def id
        @id ||= 'omnitrade'
      end

      def name
        @name ||= 'Omnitrade'
      end

      def website
        @website ||= 'https://omnitrade.io/'
      end

      def values(bases = ['BTC'], quotes = ['BRL'])
        response = API.request(API.url_tickers(bases, quotes))
        incr_requests_count

        bases.product(quotes).each_with_object({}) do |pair, result|
          base, quote = pair
          data = find_coin(base, quote, response)

          result[base] ||= {}
          result[base][quote] = find_value(base, quote, data)
        end
      end

      private

      def find_value(base, quote, data)
        data.dig('ticker', 'last')&.to_d ||
          (raise CoinPrice::ValueNotFoundError, "#{base}/#{quote}")
      end

      def find_coin(base, quote, response)
        response.dig(API::COIN_ID[base] + API::COIN_ID[quote]) || response
      end
    end
  end
end
