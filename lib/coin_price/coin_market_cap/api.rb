module CoinPrice
  module CoinMarketCap
    class API
      class << self
        def endpoint
          @endpoint ||= 'https://pro-api.coinmarketcap.com/v1'
        end

        def key
          CoinPrice.config.coinmarketcap_api_key
        end

        def max_request_retries
          CoinPrice.config.max_request_retries
        end

        def code_id(code)
          @code_id ||= {
            'BTC'  => 1,
            'BCH'  => 1831,
            'BTG'  => 2083,
            'LTC'  => 2,
            'ETH'  => 1027,
            'DASH' => 131,
            'XRP'  => 52,
            'DCR'  => 1168,
            'MFT'  => 2896,
            'USDC' => 3408,
            'BNB'  => 1839
          }
          @code_id[code]
        end

        def requests_count(date = Time.now.strftime('%Y-%m-%d'))
          CoinPrice.redis.get("#{CacheKey.requests_count}:#{date}")&.to_i || 0
        end

        def request(url, options = {})
          options[:headers] = {
            'X-CMC_PRO_API_KEY' => key,
            'Content-Type' => 'application/json'
          }
          retries = 0
          begin
            response = send_request(url, options)
            check_response(response)
            incr_requests_count

            response[:body]
          rescue CoinPrice::RequestError
            raise
          rescue StandardError => e
            if (retries += 1) < max_request_retries
              sleep 1
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

          unless code == 200 && error_code&.zero?
            raise CoinPrice::RequestError, "#{code}: (#{error_code}) #{error_message}"
          end
        end

        def incr_requests_count(date = Time.now.strftime('%Y-%m-%d'))
          CoinPrice.redis.incr("#{CacheKey.requests_count}:#{date}")
        end
      end
    end
  end
end
