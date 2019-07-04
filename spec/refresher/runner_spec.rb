require 'spec_helper'

describe CoinPrice::Refresher::Runner do
  let(:bases)  { ['XXX', 'YYY'] }
  let(:quotes) { ['AAA', 'XXX'] }
  let(:source) { 'any-source' }
  class AnySource < CoinPrice::Source; end
  let(:source_klass) { AnySource }

  let(:runner) do
    CoinPrice::Refresher::Runner.new(bases, quotes, source)
  end

  before do
    allow(CoinPrice).to receive(:find_source_klass).with(source).and_return(source_klass)
  end

  describe '#wait_seconds' do
    before do
      CoinPrice::Refresher.configure do |config|
        config.wait = 60
        config.wait_weekend_multiplier = 3
        config.wait_weekday_multiplier = 3
      end
    end

    it 'multiplies the wait time and returns' do
      expect(runner.wait_seconds).to eq(180)
    end
  end

  describe '#multiplier' do
    before do
      CoinPrice::Refresher.configure do |config|
        config.wait_weekend_multiplier = 1
        config.wait_weekday_multiplier = 2
      end
    end

    context 'when it is weekend' do
      let(:saturday) { Time.parse('2019-06-29T11:59:59Z') }
      let(:sunday)   { Time.parse('2019-06-30T11:59:59Z') }

      it 'returns weekend multiplier' do
        expect(runner.multiplier(saturday)).to eq(CoinPrice::Refresher.config.wait_weekend_multiplier)

        expect(runner.multiplier(sunday)).to eq(CoinPrice::Refresher.config.wait_weekend_multiplier)
      end
    end

    context 'when it is not weekend' do
      let(:monday) { Time.parse('2019-07-01T11:59:59Z') }

      it 'returns weekday multiplier' do
        expect(runner.multiplier(monday)).to eq(CoinPrice::Refresher.config.wait_weekday_multiplier)
      end
    end
  end
end
