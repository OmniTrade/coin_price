module CoinPrice
  module CoinMarketCap
    class API
      ENDPOINT = 'https://pro-api.coinmarketcap.com/v1'
      ENDPOINT_CONVERSION = "#{ENDPOINT}/tools/price-conversion"
      ENDPOINT_LISTINGS = "#{ENDPOINT}/cryptocurrency/listings/latest"

      CODE_ID = {
        'BTC' => 1,
        'BCH' => 1831,
        'BTG' => 2083,
        'LTC' => 2,
        'ETH' => 1027,
        'DASH' => 131,
        'XRP' => 52,
        'DCR' => 1168,
        'MFT' => 2896,
        'USDC' => 3408,
        'BNB' => 1839
      }

      class << self
        def url_conversion(base, quote)
          id = "id=#{CODE_ID[base]}"
          convert = CODE_ID[quote] ? "convert_id=#{CODE_ID[quote]}" : "convert=#{quote}"
          amount = 'amount=1'

          "#{ENDPOINT_CONVERSION}?#{id}&#{convert}&#{amount}"
        end

        def url_listings(quote, limit = CoinMarketCap.config.listings_limit)
          convert = CODE_ID[quote] ? "convert_id=#{CODE_ID[quote]}" : "convert=#{quote}"
          limit = "limit=#{limit}" # maximum limit is 5_000

          "#{ENDPOINT_LISTINGS}?#{convert}&#{limit}"
        end

        def request(url, options = {})
          options[:headers] = {
            'X-CMC_PRO_API_KEY' => CoinMarketCap.config.api_key,
            'Content-Type' => 'application/json'
          }
          retries = 0
          begin
            response = send_request(url, options)
            check_response(response)

            response[:body]
          rescue CoinPrice::RequestError
            raise
          rescue StandardError => e
            if (retries += 1) < CoinMarketCap.config.max_request_retries
              sleep CoinMarketCap.config.wait_between_requests
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

          error_code = response[:body].dig('status', 'error_code')
          error_message = response[:body].dig('status', 'error_message')

          raise CoinPrice::RequestError, "#{code}: (#{error_code}) #{error_message}" \
            unless code == 200 && error_code&.zero?
        end
      end
    end
  end
end
