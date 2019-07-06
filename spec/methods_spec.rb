require 'spec_helper'

describe CoinPrice do
  let(:base)  { 'XXX' }
  let(:quote) { 'YYY' }
  let(:bases)  { ['XXX', 'YYY'] }
  let(:quotes) { ['AAA', 'XXX'] }

  let(:source_id) { 'any-source' }
  class AnySource < CoinPrice::Source; end
  let(:source_class) { AnySource }
  let(:options) { { any_option: 'any_value' } }

  describe '.value' do
    let(:result) do
      { base => { quote => '9101.42'.to_d } }
    end

    before do
      allow(CoinPrice).to receive(:values).with(any_args).and_return(result)
    end

    it 'calls .values' do
      expect(CoinPrice).to receive(:values).with([base], [quote], source_id, options).once

      CoinPrice.value(base, quote, source_id, options)
    end

    it 'returns the value' do
      expect(CoinPrice.value(base, quote, source_id, options)).to eq(result[base][quote])
    end
  end

  describe '.values' do
    context 'when source exists' do
      let(:result) do
        {
          bases[0] => {
            quotes[0] => '9101.42'.to_d,
            quotes[1] => '1'.to_d
          },
          bases[1] => {
            quotes[0] => '202.42'.to_d,
            quotes[1] => '0.022'.to_d
          }
        }
      end

      before do
        allow(CoinPrice).to receive(:find_source_class).with(source_id).and_return(source_class)
        allow_any_instance_of(CoinPrice::Fetch).to receive(:values).and_return(result)
      end

      it 'finds the source class and instance a Fetch' do
        expect(CoinPrice).to receive(:find_source_class).with(source_id).once
        expect(CoinPrice::Fetch).to receive(:new).with(bases, quotes, source_class, options).once.and_call_original

        CoinPrice.values(bases, quotes, source_id, options)
      end

      it 'returns Fetch#values' do
        expect(CoinPrice.values(bases, quotes, source_id, options)).to eq(result)
      end
    end

    context 'when source does not exist' do
      let(:non_existent_source_id) { 'non-existent-source-id' }

      before do
        allow(CoinPrice.sources).to receive(:dig).with(non_existent_source_id, 'class').and_return(nil)
      end

      it 'raises UnknownSourceError' do
        expect do
          CoinPrice.values(bases, quotes, non_existent_source_id, options)
        end.to raise_error(CoinPrice::UnknownSourceError, /#{non_existent_source_id}/)
      end
    end
  end

  describe '.timestamp' do
    let(:result) do
      { base => { quote => 1562177867 } }
    end

    before do
      allow(CoinPrice).to receive(:timestamps).with(any_args).and_return(result)
    end

    it 'calls .timestamps' do
      expect(CoinPrice).to receive(:timestamps).with([base], [quote], source_id).once

      CoinPrice.timestamp(base, quote, source_id)
    end

    it 'returns the timestamp' do
      expect(CoinPrice.timestamp(base, quote, source_id)).to eq(result[base][quote])
    end
  end

  describe '.timestamps' do
    context 'when source exists' do
      let(:result) do
        {
          bases[0] => {
            quotes[0] => 1562180583,
            quotes[1] => 1562180583
          },
          bases[1] => {
            quotes[0] => 1562180583,
            quotes[1] => 1562180583
          }
        }
      end

      before do
        allow(CoinPrice).to receive(:find_source_class).with(source_id).and_return(source_class)
        allow_any_instance_of(CoinPrice::Fetch).to receive(:timestamps).and_return(result)
      end

      it 'finds the source class and instance a Fetch' do
        expect(CoinPrice).to receive(:find_source_class).with(source_id).once
        expect(CoinPrice::Fetch).to receive(:new).with(bases, quotes, source_class).once.and_call_original

        CoinPrice.timestamps(bases, quotes, source_id)
      end

      it 'returns Fetch#timestamps' do
        expect(CoinPrice.timestamps(bases, quotes, source_id)).to eq(result)
      end
    end

    context 'when source does not exist' do
      let(:non_existent_source_id) { 'non-existent-source-id' }

      before do
        allow(CoinPrice.sources).to receive(:dig).with(non_existent_source_id, 'class').and_return(nil)
      end

      it 'raises UnknownSourceError' do
        expect do
          CoinPrice.timestamps(bases, quotes, non_existent_source_id)
        end.to raise_error(CoinPrice::UnknownSourceError, /#{non_existent_source_id}/)
      end
    end
  end

  describe '.requests_count' do
    context 'when source exists' do
      let(:result) { 8 }

      before do
        allow(CoinPrice).to receive(:find_source_class).with(source_id).and_return(source_class)
        allow_any_instance_of(CoinPrice::Source).to receive(:requests_count).and_return(result)
      end

      it 'instances a Source and returns Source#requests_count' do
        expect(CoinPrice::Source).to receive(:new).once.and_call_original
        expect(CoinPrice.requests_count(source_id)).to eq(result)
      end
    end

    context 'when source does not exist' do
      let(:non_existent_source_id) { 'non-existent-source-id' }

      before do
        allow(CoinPrice.sources).to receive(:dig).with(non_existent_source_id, 'class').and_return(nil)
      end

      it 'raises UnknownSourceError' do
        expect do
          CoinPrice.requests_count(non_existent_source_id)
        end.to raise_error(CoinPrice::UnknownSourceError, /#{non_existent_source_id}/)
      end
    end
  end

  describe '.find_source_class' do
    context 'when source exists' do
      before do
        allow(CoinPrice.sources).to receive(:dig).with(source_id, 'class').and_return(source_class)
      end

      it 'returns the Source class' do
        expect(CoinPrice.find_source_class(source_id)).to eq(source_class)
      end
    end

    context 'when source does not exist' do
      before do
        allow(CoinPrice.sources).to receive(:dig).with(source_id, 'class').and_return(nil)
      end

      it 'raises UnknownSourceError' do
        expect do
          CoinPrice.find_source_class(source_id)
        end.to raise_error(CoinPrice::UnknownSourceError, /#{source_id}/)
      end
    end
  end

  describe '.cache_key' do
    let(:my_custom_prefix) { 'my-custom-prefix' }

    before do
      allow(CoinPrice.config).to receive(:cache_key_prefix).and_return(my_custom_prefix)
    end

    it 'prefixes config.cache_key_prefix' do
      expect(CoinPrice.cache_key).to eq("#{my_custom_prefix}coin-price")
    end
  end
end
