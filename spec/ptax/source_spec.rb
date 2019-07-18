require 'spec_helper'

describe CoinPrice::PTAX::Source do
  let(:source) { CoinPrice::PTAX::Source.new }

  describe '#values' do
    context "when bases, quotes don't equal ['USD'], ['BRL']" do
      let(:bases)  { ['XXX'] }
      let(:quotes) { ['YYY'] }

      it 'raises CoinPrice::ValueNotFoundError' do
        expect do
          source.values(bases, quotes)
        end.to raise_error(CoinPrice::ValueNotFoundError)
      end
    end

    context "when bases, quotes equal ['USD'], ['BRL']" do
      let(:bases)  { ['USD'] }
      let(:quotes) { ['BRL'] }

      let(:url_cotacao_dolar_dia) { CoinPrice::PTAX::API.url_cotacao_dolar_dia }
      let(:code) { 'defined by each sub test' }
      let(:body_json_filename) { 'defined by each sub test' }
      let(:body) do
        filepath = File.join(__dir__, '../', 'resources', source.id, 'endpoint_cotacao_dolar_dia', body_json_filename)
        JSON.parse(File.read(filepath))
      end

      before do
        allow(CoinPrice::PTAX::API).to \
          receive(:send_request)
          .with(url_cotacao_dolar_dia, any_args)
          .and_return(code: code, body: body)
      end

      describe 'requests to url_cotacao_dolar_dia' do
        describe 'successful (200)' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          let(:values) do
            {
              bases[0] => {
                quotes[0] => 3.7489.to_d
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

        describe 'any HTTP status code different than 200' do
          let(:code) { 999 }
          let(:body_json_filename) { '999_generic_error.json' }

          it 'raises CoinPrice::RequestError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::RequestError, /999/)
          end
        end

        describe 'a call on market holidays or at weekends' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_on_market_holidays_or_at_weekends.json' }

          it 'raises CoinPrice::ValueNotFoundError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end

        describe 'could not find price value for base/quote in response' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful_without_cotacao_venda.json' }

          it 'raises CoinPrice::ValueNotFoundError' do
            expect do
              source.values(bases, quotes)
            end.to raise_error(CoinPrice::ValueNotFoundError)
          end
        end

        describe 'any StandardError occurred in CoinPrice::PTAX::API' do
          let(:code) { 200 }
          let(:body_json_filename) { '200_successful.json' }

          before do
            allow(CoinPrice::PTAX::API).to \
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
