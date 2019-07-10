require 'spec_helper'

describe CoinPrice::Refresher::Runner do
  let(:bases)  { ['XXX', 'YYY'] }
  let(:quotes) { ['AAA', 'XXX'] }
  let(:source_id) { 'any-source' }
  class AnySource < CoinPrice::Source; end
  let(:source_class) { AnySource }

  let(:runner) do
    CoinPrice::Refresher::Runner.new(bases, quotes, source_id)
  end

  before do
    allow(CoinPrice).to receive(:find_source_class).with(source_id).and_return(source_class)
  end

  describe '#wait' do
    let(:refresher_config_wait) { 100 }

    before do
      CoinPrice::Refresher.configure do |config|
        config.wait = refresher_config_wait
      end
    end

    context 'when options[:wait] is not set' do
      it 'returns Refresher.config.wait' do
        expect(runner.wait).to eq(refresher_config_wait)
      end
    end

    context 'when options[:wait] is set' do
      let(:options_wait) { 200 }
      let(:runner) { CoinPrice::Refresher::Runner.new(bases, quotes, source_id, wait: options_wait) }

      it 'overwrites Refresher.config.wait' do
        expect(runner.wait).to eq(options_wait)
      end
    end
  end

  describe '#wait_weekday_multiplier' do
    let(:refresher_config_wait_weekday_multiplier) { 10 }

    before do
      CoinPrice::Refresher.configure do |config|
        config.wait_weekday_multiplier = refresher_config_wait_weekday_multiplier
      end
    end

    context 'when options[:wait_weekday_multiplier] is not set' do
      it 'returns Refresher.config.wait_weekday_multiplier' do
        expect(runner.wait_weekday_multiplier).to eq(refresher_config_wait_weekday_multiplier)
      end
    end

    context 'if options[:wait_weekday_multiplier] is set' do
      let(:options_wait_weekday_multiplier) { 20 }
      let(:runner) do
        CoinPrice::Refresher::Runner.new(
          bases, quotes, source_id,
          wait_weekday_multiplier: options_wait_weekday_multiplier
        )
      end

      it 'overwrites Refresher.config.wait_weekday_multiplier' do
        expect(runner.wait_weekday_multiplier).to eq(options_wait_weekday_multiplier)
      end
    end
  end

  describe '#wait_weekend_multiplier' do
    let(:refresher_config_wait_weekend_multiplier) { 10 }

    before do
      CoinPrice::Refresher.configure do |config|
        config.wait_weekend_multiplier = refresher_config_wait_weekend_multiplier
      end
    end

    context 'when options[:wait_weekend_multiplier] is not set' do
      it 'returns Refresher.config.wait_weekend_multiplier' do
        expect(runner.wait_weekend_multiplier).to eq(refresher_config_wait_weekend_multiplier)
      end
    end

    context 'if options[:wait_weekend_multiplier] is set' do
      let(:options_wait_weekend_multiplier) { 20 }
      let(:runner) do
        CoinPrice::Refresher::Runner.new(
          bases, quotes, source_id,
          wait_weekend_multiplier: options_wait_weekend_multiplier
        )
      end

      it 'overwrites Refresher.config.wait_weekend_multiplier' do
        expect(runner.wait_weekend_multiplier).to eq(options_wait_weekend_multiplier)
      end
    end
  end

  describe '#wait_seconds' do
    before do
      CoinPrice::Refresher.configure do |config|
        config.wait = 60
      end
      allow(runner).to receive(:multiplier).and_return(3)
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
