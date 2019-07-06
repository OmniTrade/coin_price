require 'spec_helper'

describe CoinPrice::Source do
  let(:source) { CoinPrice::Source.new }

  describe '#id' do
    it 'is an abstract method and must be implemented' do
      expect do
        source.id
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#values' do
    it 'is an abstract method and must be implemented' do
      expect do
        source.values
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#name' do
    it 'is an abstract method and must be implemented' do
      expect do
        source.name
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#website' do
    it 'is an abstract method and must be implemented' do
      expect do
        source.website
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#incr_requests_count' do
    let(:cache_key_requests_count) { 'its-cache-key-requests-count' }
    let(:number) { 1 }

    before do
      allow(source).to receive(:cache_key_requests_count).with(any_args).and_return(cache_key_requests_count)
    end

    it 'calls CoinPrice.cache.incrby' do
      expect(CoinPrice.cache).to receive(:incrby).with(cache_key_requests_count, number).once

      source.incr_requests_count(number)
    end

    it 'increments in cache the number of requests performed on a date' do
      expect(CoinPrice.cache.get(cache_key_requests_count)).to eq(nil)

      source.incr_requests_count(1)
      expect(CoinPrice.cache.get(cache_key_requests_count)).to eq('1')

      source.incr_requests_count(1)
      source.incr_requests_count(1)
      expect(CoinPrice.cache.get(cache_key_requests_count)).to eq('3')

      source.incr_requests_count(5)
      expect(CoinPrice.cache.get(cache_key_requests_count)).to eq('8')
    end
  end

  describe '#requests_count' do
    let(:cache_key_requests_count) { 'its-cache-key-requests-count' }

    before do
      allow(source).to receive(:cache_key_requests_count).with(any_args).and_return(cache_key_requests_count)
    end

    context 'when no counter is found' do
      let(:zero) { 0 }

      before do
        allow_any_instance_of(CoinPrice::Cache).to receive(:get).with(cache_key_requests_count).and_return(nil)
      end

      it 'calls CoinPrice.cache.get' do
        expect(CoinPrice.cache).to receive(:get).with(cache_key_requests_count).once

        source.requests_count
      end

      it 'returns zero' do
        expect(source.requests_count).to eq(zero)
      end
    end

    context 'when there is a counter' do
      let(:count) { 8 }

      before do
        allow_any_instance_of(CoinPrice::Cache).to receive(:get).with(cache_key_requests_count).and_return(count)
      end

      it 'calls CoinPrice.cache.get' do
        expect(CoinPrice.cache).to receive(:get).with(cache_key_requests_count).once

        source.requests_count
      end

      it 'reads from cache and returns the number of requets performed on a date' do
        expect(source.requests_count).to eq(count)
      end
    end
  end

  describe '#cache_key' do
    let(:id) { 'any-source-id' }

    before do
      allow(source).to receive(:id).and_return(id)
    end

    it 'concats CoinPrice.cache_key and id' do
      expect(source.cache_key).to eq("#{CoinPrice.cache_key}:#{id}")
    end
  end

  describe '#cache_key_requests_count' do
    let(:cache_key) { 'its-cache-key' }
    let(:date) { '2009-01-03' }

    before do
      allow(source).to receive(:cache_key).and_return(cache_key)
    end

    it 'concats its cache_key, "requests-count" and the given date' do
      expect(source.cache_key_requests_count(date)).to eq("#{cache_key}:requests-count:#{date}")
    end
  end
end
