require 'spec_helper'

describe CoinPrice do
  context 'from source "coinmarketcap"' do
    let(:source) { 'coinmarketcap' }

    let(:base)  { 'BTC' }
    let(:quote) { 'USD' }
    let(:latest_base_quote) { CoinPrice::CoinMarketCap::Latest.new(base, quote) }
    let(:cache_key_value_base_quote) { latest_base_quote.cache_key_value }
    let(:cache_key_timestamp_base_quote) { latest_base_quote.cache_key_timestamp }

    let(:bases)  { ['BTC', 'ETH', 'LTC'] }
    let(:quotes) { ['USD', 'BTC'] }

    let(:latest_base0_quote0) { CoinPrice::CoinMarketCap::Latest.new(bases[0], quotes[0]) }
    let(:latest_base0_quote1) { CoinPrice::CoinMarketCap::Latest.new(bases[0], quotes[1]) }
    let(:cache_key_value_base0_quote0) { latest_base0_quote0.cache_key_value }
    let(:cache_key_value_base0_quote1) { latest_base0_quote1.cache_key_value }
    let(:cache_key_timestamp_base0_quote0) { latest_base0_quote0.cache_key_timestamp }
    let(:cache_key_timestamp_base0_quote1) { latest_base0_quote1.cache_key_timestamp }

    let(:latest_base1_quote0) { CoinPrice::CoinMarketCap::Latest.new(bases[1], quotes[0]) }
    let(:latest_base1_quote1) { CoinPrice::CoinMarketCap::Latest.new(bases[1], quotes[1]) }
    let(:cache_key_value_base1_quote0) { latest_base1_quote0.cache_key_value }
    let(:cache_key_value_base1_quote1) { latest_base1_quote1.cache_key_value }
    let(:cache_key_timestamp_base1_quote0) { latest_base1_quote0.cache_key_timestamp }
    let(:cache_key_timestamp_base1_quote1) { latest_base1_quote1.cache_key_timestamp }

    let(:latest_base2_quote0) { CoinPrice::CoinMarketCap::Latest.new(bases[2], quotes[0]) }
    let(:latest_base2_quote1) { CoinPrice::CoinMarketCap::Latest.new(bases[2], quotes[1]) }
    let(:cache_key_value_base2_quote0) { latest_base2_quote0.cache_key_value }
    let(:cache_key_value_base2_quote1) { latest_base2_quote1.cache_key_value }
    let(:cache_key_timestamp_base2_quote0) { latest_base2_quote0.cache_key_timestamp }
    let(:cache_key_timestamp_base2_quote1) { latest_base2_quote1.cache_key_timestamp }

    context 'get latest price' do
      context 'when sending request' do
        let(:body) { JSON.parse(File.read(File.join(__dir__, 'resources', source, 'latest', body_json_file))) }

        before do
          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
              .with(latest_base_quote.url, any_args)
              .and_return({ code: code, body: body})
        end

        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_file) { '200_successful.json' }

          let(:value) { 9216.02631123.to_d }

          it 'fetches and returns the latest price from source' do
            expect(CoinPrice.latest(base, quote, source)).to eq(value)
          end

          it 'caches the latest price value in Redis' do
            CoinPrice.latest(base, quote, source)

            expect(CoinPrice.redis.get(cache_key_value_base_quote)).to eq(value.to_s)
          end

          it 'stores the latest price timestamp in Redis' do
            CoinPrice.latest(base, quote, source)

            expect(CoinPrice.redis.get(cache_key_timestamp_base_quote).to_i).to be > 0
          end

          it 'increments requests count for source' do
            expect(CoinPrice.requests_count(source)).to eq(0)

            CoinPrice.latest(base, quote, source)
            expect(CoinPrice.requests_count(source)).to eq(1)

            CoinPrice.latest(base, quote, source)
            CoinPrice.latest(base, quote, source)
            expect(CoinPrice.requests_count(source)).to eq(3)
          end
        end

        describe 'bad request (400)' do
          let(:code) { 400 }
          let(:body_json_file) { '400_bad_request.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /400: \(400\)/)
          end
        end

        describe 'unauthorized (401)' do
          let(:code) { 401 }
          let(:body_json_file) { '401_unauthorized.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /401: \(401\)/)
          end
        end

        describe 'forbidden (403)' do
          let(:code) { 403 }
          let(:body_json_file) { '403_forbidden.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /403: \(403\)/)
          end
        end

        describe 'too many requests (429)' do
          let(:code) { 429 }
          let(:body_json_file) { '429_too_many_requests.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /429: \(429\)/)
          end
        end

        describe 'internal server error (500)' do
          let(:code) { 500 }
          let(:body_json_file) { '500_internal_server_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /500: \(500\)/)
          end
        end

        describe 'any "status.error_code" different than 0 in response body' do
          let(:code) { 200 }
          let(:body_json_file) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /200: \(999\)/)
          end
        end

        describe 'any HTTP status code different than 200' do
          let(:code) { 999 }
          let(:body_json_file) { '200_successful.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError, /999:/)
          end
        end

        describe 'could not find price value for base/quote in response' do
          let(:code) { 200 }
          let(:body_json_file) { '200_without_base_quote_price.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::ValueNotFoundError, /#{base}\/#{quote}/)
          end
        end

        describe 'any StandardError occurred CoinMarketCap::API' do
          let(:code) { 200 }
          let(:body_json_file) { '200_successful.json' }

          before do
            allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
              .and_raise(StandardError)
          end

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.latest(base, quote, source)
            }.to raise_error(CoinPrice::RequestError)
          end
        end
      end

      context 'when reading from cache' do
        let(:value) { 9101.42.to_d }

        describe 'successfully' do
          before do
            CoinPrice.redis.set(cache_key_value_base_quote, value)
          end

          it 'returns the price value' do
            expect(CoinPrice.latest(base, quote, source, from_cache: true)).to eq(value)
          end
        end

        describe 'an error occured' do
          it 'raises CoinPrice::CacheError' do
            expect {
              CoinPrice.latest(base, quote, source, from_cache: true)
            }.to raise_error(CoinPrice::CacheError)
          end
        end
      end
    end

    context 'get listings' do
      let(:listings) { CoinPrice::CoinMarketCap::Listings.new(bases, quotes) }
      let(:listings_quote0_url) { listings.url(quotes[0]) }
      let(:listings_quote1_url) { listings.url(quotes[1]) }

      context 'when sending request' do
        let(:body_quote0) { JSON.parse(File.read(File.join(__dir__, 'resources', source, 'listings', body_quote0_json_file))) }
        let(:body_quote1) { JSON.parse(File.read(File.join(__dir__, 'resources', source, 'listings', body_quote1_json_file))) }

        before do
          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
              .with(listings_quote0_url, any_args)
              .and_return({ code: code0, body: body_quote0 })

          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
              .with(listings_quote1_url, any_args)
              .and_return({ code: code1, body: body_quote1 })
        end

        describe 'successful (200)' do
          let(:code0) { 200 }
          let(:code1) { 200 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '200_successful_quote1.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 9044.00258585.to_d,
                quotes[1] => 1.to_d
              },
              bases[1] => {
                quotes[0] => 265.767427441.to_d,
                quotes[1] => 0.029425969139927295.to_d
              },
              bases[2] => {
                quotes[0] => 132.813109717.to_d,
                quotes[1] => 0.014728113539223318.to_d
              }
            }
          end

          it 'fetches and returns the list of latest prices from source' do
            expect(CoinPrice.listings(bases, quotes, source)).to eq(values)
          end

          it 'caches the latest prices values in Redis' do
            CoinPrice.listings(bases, quotes, source)

            expect(CoinPrice.redis.get(cache_key_value_base0_quote0)).to eq(values[bases[0]][quotes[0]].to_s)
            expect(CoinPrice.redis.get(cache_key_value_base0_quote1)).to eq(values[bases[0]][quotes[1]].to_s)

            expect(CoinPrice.redis.get(cache_key_value_base1_quote0)).to eq(values[bases[1]][quotes[0]].to_s)
            expect(CoinPrice.redis.get(cache_key_value_base1_quote1)).to eq(values[bases[1]][quotes[1]].to_s)

            expect(CoinPrice.redis.get(cache_key_value_base2_quote0)).to eq(values[bases[2]][quotes[0]].to_s)
            expect(CoinPrice.redis.get(cache_key_value_base2_quote1)).to eq(values[bases[2]][quotes[1]].to_s)
          end

          it 'stores the latest prices timestamps in Redis' do
            CoinPrice.listings(bases, quotes, source)

            expect(CoinPrice.redis.get(cache_key_timestamp_base0_quote0).to_i).to be > 0
            expect(CoinPrice.redis.get(cache_key_timestamp_base0_quote1).to_i).to be > 0

            expect(CoinPrice.redis.get(cache_key_timestamp_base1_quote0).to_i).to be > 0
            expect(CoinPrice.redis.get(cache_key_timestamp_base1_quote1).to_i).to be > 0

            expect(CoinPrice.redis.get(cache_key_timestamp_base2_quote0).to_i).to be > 0
            expect(CoinPrice.redis.get(cache_key_timestamp_base2_quote1).to_i).to be > 0
          end

          it 'increments requests count for source' do
            expect(CoinPrice.requests_count(source)).to eq(0)

            CoinPrice.listings(bases, quotes, source)
            expect(CoinPrice.requests_count(source)).to eq(2) # with CoinMarketCap, we send one request for each quote

            CoinPrice.listings(bases, quotes, source)
            CoinPrice.listings(bases, quotes, source)
            expect(CoinPrice.requests_count(source)).to eq(6)
          end
        end

        describe 'at least one bad request (400)' do
          let(:code0) { 200 }
          let(:code1) { 400 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '400_bad_request.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /400: \(400\)/)
          end
        end

        describe 'at least one unauthorized (401)' do
          let(:code0) { 200 }
          let(:code1) { 401 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '401_unauthorized.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /401: \(401\)/)
          end
        end

        describe 'at least one forbidden (403)' do
          let(:code0) { 200 }
          let(:code1) { 403 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '403_forbidden.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /403: \(403\)/)
          end
        end

        describe 'at least one too many requests (429)' do
          let(:code0) { 200 }
          let(:code1) { 429 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '429_too_many_requests.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /429: \(429\)/)
          end
        end

        describe 'at least one internal server error (500)' do
          let(:code0) { 200 }
          let(:code1) { 500 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '500_internal_server_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /500: \(500\)/)
          end
        end

        describe 'at least one with any "status.error_code" different than 0 in response body' do
          let(:code0) { 200 }
          let(:code1) { 200 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /200: \(999\)/)
          end
        end

        describe 'at least one with any HTTP status code different than 200' do
          let(:code0) { 200 }
          let(:code1) { 999 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '200_successful_quote1.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError, /999:/)
          end
        end

        describe 'any StandardError occurred CoinMarketCap::API' do
          let(:code0) { 200 }
          let(:code1) { 200 }
          let(:body_quote0_json_file) { '200_successful_quote0.json' }
          let(:body_quote1_json_file) { '200_successful_quote1.json' }

          before do
            allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
              .and_raise(StandardError)
          end

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::RequestError)
          end
        end

        describe 'at least one value not found for base/quote' do
          let(:code0) { 200 }
          let(:code1) { 200 }
          let(:body_quote0_json_file) { '200_successful_without_some_base_quote_price.json' }
          let(:body_quote1_json_file) { '200_successful_quote1.json' }

          it 'raises CoinPrice::RequestError' do
            expect {
              CoinPrice.listings(bases, quotes, source)
            }.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end
      end

      context 'when reading from cache' do
        let(:values) do
          {
            bases[0] => {
              quotes[0] => 9101.42.to_d,
              quotes[1] => 1.to_d
            },
            bases[1] => {
              quotes[0] => 202.42.to_d,
              quotes[1] => 0.022.to_d
            },
            bases[2] => {
              quotes[0] => 101.42.to_d,
              quotes[1] => 0.011.to_d
            }
          }
        end

        describe 'successfully' do
          before do
            CoinPrice.redis.set(cache_key_value_base0_quote0, values[bases[0]][quotes[0]])
            CoinPrice.redis.set(cache_key_value_base0_quote1, values[bases[0]][quotes[1]])

            CoinPrice.redis.set(cache_key_value_base1_quote0, values[bases[1]][quotes[0]])
            CoinPrice.redis.set(cache_key_value_base1_quote1, values[bases[1]][quotes[1]])

            CoinPrice.redis.set(cache_key_value_base2_quote0, values[bases[2]][quotes[0]])
            CoinPrice.redis.set(cache_key_value_base2_quote1, values[bases[2]][quotes[1]])
          end

          it 'returns the prices values' do
            expect(CoinPrice.listings(bases, quotes, source, from_cache: true)).to eq(values)
          end
        end

        describe 'an error occured' do
          it 'raises CoinPrice::CacheError' do
            expect {
              CoinPrice.listings(bases, quotes, source, from_cache: true)
            }.to raise_error(CoinPrice::CacheError)
          end
        end
      end
    end
  end
end
