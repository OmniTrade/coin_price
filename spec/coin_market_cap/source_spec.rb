require 'spec_helper'

describe CoinPrice::CoinMarketCap::Source do
  let(:source) { CoinPrice::CoinMarketCap::Source.new }

  describe '#values' do
    context 'when there is only one base and one quote' do
      let(:base)  { 'BTC' }
      let(:quote) { 'USD' }
      let(:bases)  { [base] }
      let(:quotes) { [quote] }

      it 'calls private fetch_conversion method' do
        expect(source).to receive(:fetch_conversion).with(bases.first, quotes.first).once

        source.values(bases, quotes)
      end

      describe 'requests to url_conversion' do
        let(:url_conversion) { CoinPrice::CoinMarketCap::API.url_conversion(base, quote) }
        let(:code) { 'defined by each sub test' }
        let(:body_json_filename) { 'defined by each sub test' }
        let(:body) do
          filepath = File.join(__dir__, '../', 'resources', source.id, 'endpoint_conversion', body_json_filename)
          JSON.parse(File.read(filepath))
        end

        before do
          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
            .with(url_conversion, any_args)
            .and_return(code: code, body: body)
        end

        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          let(:values) do
            { base => { quote => 9216.02631123.to_d } }
          end

          it 'fetches and returns the latest price' do
            expect(source.values(bases, quotes)).to eq(values)
          end

          it 'increments requests count for source' do
            expect(source.requests_count).to eq(0)

            source.values(bases, quotes)
            expect(source.requests_count).to eq(1)

            source.values(bases, quotes)
            source.values(bases, quotes)
            expect(source.requests_count).to eq(3)
          end
        end

        describe 'bad request (400)' do
          let(:code) { 400 }
          let(:body_json_filename) { '400_bad_request.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /400: \(400\)/)
          end
        end

        describe 'unauthorized (401)' do
          let(:code) { 401 }
          let(:body_json_filename) { '401_unauthorized.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /401: \(401\)/)
          end
        end

        describe 'forbidden (403)' do
          let(:code) { 403 }
          let(:body_json_filename) { '403_forbidden.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /403: \(403\)/)
          end
        end

        describe 'too many requests (429)' do
          let(:code) { 429 }
          let(:body_json_filename) { '429_too_many_requests.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /429: \(429\)/)
          end
        end

        describe 'internal server error (500)' do
          let(:code) { 500 }
          let(:body_json_filename) { '500_internal_server_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /500: \(500\)/)
          end
        end

        describe 'any "status.error_code" different than 0 in response body' do
          let(:code) { 200 }
          let(:body_json_filename) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /200: \(999\)/)
          end
        end

        describe 'any HTTP status code different than 200' do
          let(:code) { 999 }
          let(:body_json_filename) { '200_successful.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /999:/)
          end
        end

        describe 'could not find price value for base/quote in response' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_without_base_quote_price.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError, %r{#{base}\/#{quote}})
          end
        end

        describe 'any StandardError occurred in CoinPrice::CoinMarketCap::API' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          before do
            allow(CoinPrice::CoinMarketCap::API).to \
              receive(:send_request).and_raise(StandardError)
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError)
          end
        end
      end
    end

    context 'when there are many bases and quotes' do
      let(:bases)  { ['BTC', 'ETH', 'LTC'] }
      let(:quotes) { ['USD', 'BTC'] }

      before do
        CoinPrice::CoinMarketCap.configure do |config|
          config.wait_between_requests = 0
        end
      end

      it 'calls private fetch_listings method' do
        expect(source).to receive(:fetch_listings).with(bases, quotes).once

        source.values(bases, quotes)
      end

      describe 'requests to url_listings' do
        let(:url_listings) do
          [
            CoinPrice::CoinMarketCap::API.url_listings(quotes[0]),
            CoinPrice::CoinMarketCap::API.url_listings(quotes[1])
          ]
        end
        let(:code) { ['defined by each sub test', 'defined by each sub test'] }
        let(:body_json_filename) { ['defined by each sub test', 'defined by each sub test'] }
        let(:body) do
          filepath0 = File.join(__dir__, '../', 'resources', source.id, 'endpoint_listings', body_json_filename[0])
          filepath1 = File.join(__dir__, '../', 'resources', source.id, 'endpoint_listings', body_json_filename[1])
          [
            JSON.parse(File.read(filepath0)),
            JSON.parse(File.read(filepath1))
          ]
        end

        before do
          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
            .with(url_listings[0], any_args)
            .and_return(code: code[0], body: body[0])

          allow(CoinPrice::CoinMarketCap::API).to \
            receive(:send_request)
            .with(url_listings[1], any_args)
            .and_return(code: code[1], body: body[1])
        end

        describe 'successful (200)' do
          let(:code) { [200, 200] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '200_successful_quote1.json'
            ]
          end
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

          it 'fetches and returns the list of latest prices' do
            expect(source.values(bases, quotes)).to eq(values)
          end

          it 'increments requests count' do
            expect(source.requests_count).to eq(0)

            source.values(bases, quotes)
            expect(source.requests_count).to eq(2) # with CoinMarketCap, we send one request for each quote

            source.values(bases, quotes)
            source.values(bases, quotes)
            expect(source.requests_count).to eq(6)
          end
        end

        describe 'at least one bad request (400)' do
          let(:code) { [200, 400] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '400_bad_request.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /400: \(400\)/)
          end
        end

        describe 'at least one unauthorized (401)' do
          let(:code) { [200, 401] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '401_unauthorized.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /401: \(401\)/)
          end
        end

        describe 'at least one forbidden (403)' do
          let(:code) { [200, 403] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '403_forbidden.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /403: \(403\)/)
          end
        end

        describe 'at least one too many requests (429)' do
          let(:code) { [200, 429] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '429_too_many_requests.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /429: \(429\)/)
          end
        end

        describe 'at least one internal server error (500)' do
          let(:code) { [200, 500] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '500_internal_server_error.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /500: \(500\)/)
          end
        end

        describe 'at least one with any "status.error_code" different than 0 in response body' do
          let(:code) { [200, 200] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '999_generic_error.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /200: \(999\)/)
          end
        end

        describe 'at least one with any HTTP status code different than 200' do
          let(:code) { [200, 999] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '200_successful_quote1.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /999:/)
          end
        end

        describe 'any StandardError occurred CoinMarketCap::API' do
          let(:code) { [200, 200] }
          let(:body_json_filename) do
            [
              '200_successful_quote0.json',
              '200_successful_quote1.json'
            ]
          end

          before do
            allow(CoinPrice::CoinMarketCap::API).to \
              receive(:send_request).and_raise(StandardError)
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError)
          end
        end

        describe 'at least one base not found for base/quote' do
          let(:code) { [200, 200] }
          let(:body_json_filename) do
            [
              '200_successful_without_some_base.json',
              '200_successful_quote1.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end

        describe 'at least one quote not found for base/quote' do
          let(:code) { [200, 200] }
          let(:body_json_filename) do
            [
              '200_successful_without_some_quote.json',
              '200_successful_quote1.json'
            ]
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end
      end
    end
  end
end
