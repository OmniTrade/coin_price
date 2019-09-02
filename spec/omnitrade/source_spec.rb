require 'spec_helper'

describe CoinPrice::Omnitrade::Source do
  let(:source) { CoinPrice::Omnitrade::Source.new }

  CoinPrice::Omnitrade.configure do |config|
    config.wait_between_requests = 0
    config.max_request_retries = 0
  end

  describe '#values' do
    let(:url_tickers) { CoinPrice::Omnitrade::API.url_tickers(bases, quotes) }
    let(:code) { 'defined by each sub test' }
    let(:body_json_filename) { 'defined by each sub test' }
    let(:body) do
      filepath = File.join(__dir__, '../', 'resources', source.id, 'endpoint_tickers', body_json_filename)
      JSON.parse(File.read(filepath))
    end

    before do
      allow(CoinPrice::Omnitrade::API).to \
        receive(:send_request)
        .with(url_tickers, any_args)
        .and_return(code: code, body: body)
    end

    context 'when there is only one base and one quote' do
      let(:bases)  { ['BTC'] }
      let(:quotes) { ['BRL'] }

      describe 'requests to url_tickers with coin_id pair' do
        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_with_one_base_one_quote.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 43304.43.to_d
              }
            }
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

        describe 'too many requests (429)' do
          let(:code) { 429 }
          let(:body_json_filename) { '429_too_many_requests.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /429/)
          end
        end

        describe 'any HTTP status code different than 200' do
          let(:code) { 999 }
          let(:body_json_filename) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /999/)
          end
        end

        describe 'any StandardError occurred in CoinPrice::Omnitrade::API' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_with_one_base_one_quote.json' }

          before do
            allow(CoinPrice::Omnitrade::API).to \
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

    context 'when there are many bases and many quotes' do
      let(:bases)  { ['ETH', 'LTC'] }
      let(:quotes) { ['BTC', 'BRL'] }

      describe 'requests to url_tickers' do
        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_with_many_bases_and_quotes.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 0.0187.to_d,
                quotes[1] => 808.to_d
              },
              bases[1] => {
                quotes[0] => 0.0071.to_d,
                quotes[1] => 316.to_d
              }
            }
          end

          it 'fetches and returns the list of latest prices' do
            expect(source.values(bases, quotes)).to eq(values)
          end

          it 'increments requests count' do
            expect(source.requests_count).to eq(0)

            source.values(bases, quotes)
            expect(source.requests_count).to eq(1)

            source.values(bases, quotes)
            source.values(bases, quotes)
            expect(source.requests_count).to eq(3)
          end
        end

        describe 'too many requests (429)' do
          let(:code) { 429 }
          let(:body_json_filename) { '429_too_many_requests.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /429/)
          end
        end

        describe 'any HTTP status code different than 200' do
          let(:code) { 999 }
          let(:body_json_filename) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /999/)
          end
        end

        describe 'any StandardError occurred in CoinPrice::Omnitrade::API' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_with_many_bases_and_quotes.json' }

          before do
            allow(CoinPrice::Omnitrade::API).to \
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
  end
end
