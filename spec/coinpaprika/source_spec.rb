require 'spec_helper'

describe CoinPrice::Coinpaprika::Source do
  let(:source) { CoinPrice::Coinpaprika::Source.new }

  describe '#values' do
    let(:url_tickers) { CoinPrice::Coinpaprika::API.url_tickers(bases, quotes) }
    let(:code) { 'defined by each sub test' }
    let(:body_json_filename) { 'defined by each sub test' }
    let(:body) do
      filepath = File.join(__dir__, '../', 'resources', source.id, 'endpoint_tickers', body_json_filename)
      JSON.parse(File.read(filepath))
    end

    before do
      allow(CoinPrice::Coinpaprika::API).to \
        receive(:send_request)
        .with(url_tickers, any_args)
        .and_return(code: code, body: body)
    end

    context 'when there is only one base' do
      let(:bases)  { ['BTC'] }
      let(:quotes) { ['USD', 'BTC'] }

      describe 'requests to url_tickers with coin_id' do
        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { 'with_coin_id_200_successful.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 11296.37515253.to_d,
                quotes[1] => 1.to_d
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
          let(:body_json_filename) { 'with_coin_id_429_too_many_requests.json' }

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

        describe 'could not find price value for base/quote in response' do
          let(:code) { 200 }
          let(:body_json_filename) { 'with_coin_id_200_successful_without_some_quote.json' }

          it 'raises CoinPrice::ValueNotFoundError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end

        describe 'any StandardError occurred in CoinPrice::Coinpaprika::API' do
          let(:code) { 200 }
          let(:body_json_filename) { 'with_coin_id_200_successful.json' }

          before do
            allow(CoinPrice::Coinpaprika::API).to \
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

    context 'when there are many bases' do
      let(:bases)  { ['BTC', 'ETH', 'LTC'] }
      let(:quotes) { ['USD', 'BTC'] }

      describe 'requests to url_tickers' do
        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 11269.29032211.to_d,
                quotes[1] => 1.to_d
              },
              bases[1] => {
                quotes[0] => 291.20020217.to_d,
                quotes[1] => 0.02586434.to_d
              },
              bases[2] => {
                quotes[0] => 118.33571107.to_d,
                quotes[1] => 0.01051055.to_d
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

        describe 'at least one too many requests (429)' do
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

        describe 'any StandardError occurred Coinpaprika::API' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          before do
            allow(CoinPrice::Coinpaprika::API).to \
              receive(:send_request).and_raise(StandardError)
          end

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError)
          end
        end

        describe 'at least one base not found for base/quote' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_without_some_base.json' }

          it 'raises CoinPrice::ValueNotFoundError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end

        describe 'at least one quote not found for base/quote' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_without_some_quote.json' }

          it 'raises CoinPrice::ValueNotFoundError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end
      end
    end
  end
end
