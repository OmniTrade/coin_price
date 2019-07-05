module CoinPrice
  module Coinpaprika
    class API
      ENDPOINT = 'https://api.coinpaprika.com/v1'
      ENDPOINT_TICKERS = "#{ENDPOINT}/tickers"

      COIN_ID = {
        'BTC' => 'btc-bitcoin',
        'BCH' => 'bch-bitcoin-cash',
        'BTG' => 'btg-bitcoin-gold',
        'LTC' => 'ltc-litecoin',
        'ETH' => 'eth-ethereum',
        'DASH' => 'dash-dash',
        'XRP' => 'xrp-xrp',
        'DCR' => 'dcr-decred',
        'MFT' => 'mft-mainframe',
        'USDC' => 'usdc-usd-coin',
        'BNB' => 'bnb-binance-coin',
        'USD' => 'usd-us-dollars'
      }

      class << self
        def url_tickers(bases, quotes)
          quotes = "quotes=#{quotes.join(',')}"

          if bases.one?
            coin_id = COIN_ID[bases.first]
            "#{ENDPOINT_TICKERS}/#{coin_id}?#{quotes}"
          else
            "#{ENDPOINT_TICKERS}?#{quotes}"
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
            if (retries += 1) < Coinpaprika.config.max_request_retries
              sleep Coinpaprika.config.wait_between_requests
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
