module CoinPrice
  module Omnitrade
    class API
      ENDPOINT = 'https://omnitrade.io/api/v2'
      ENDPOINT_TICKERS = "#{ENDPOINT}/tickers"

      COIN_ID = {
        'BTC' => 'btc',
        'LTC' => 'ltc',
        'BCH' => 'bch',
        'BTG' => 'btg',
        'ETH' => 'eth',
        'DASH' => 'dash',
        'DCR' => 'dcr',
        'XRP' => 'xrp',
        'MFT' => 'mft',
        'USDC' => 'usdc',
        'BRL' => 'brl'
      }

      class << self
        def url_tickers(bases, quotes)
          if bases.one? && quotes.one?
            base = COIN_ID[bases.first]
            quote = COIN_ID[quotes.first]

            "#{ENDPOINT_TICKERS}/#{base}#{quote}"
          else
            ENDPOINT_TICKERS
          end
        end

        def request(url, options = {})
          retries = 0
          begin
            response = send_request(url, options)
            check_response(response)

            response[:body]
          rescue CoinPrice::RequestError
            raise
          rescue StandardError => e
            if (retries += 1) < Omnitrade.config.max_request_retries
              sleep Omnitrade.config.wait_between_requests
              retry
            end
            raise CoinPrice::RequestError, e.message
          end
        end

        private

        def send_request(url, options = {})
          response = HTTParty.get(url, options)
          {
            code: response.code,
            body: JSON.parse(response.body)
          }
        end

        def check_response(response)
          code = response[:code]

          raise CoinPrice::RequestError, code.to_s unless code == 200
        end
      end
    end
  end
end
