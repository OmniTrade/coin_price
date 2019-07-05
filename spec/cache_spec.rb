require 'spec_helper'

describe CoinPrice::Cache do
  let(:key) { 'any-key' }
  let(:value) { 'any-value' }
  let(:number) { 1 }

  context 'when CoinPrice.config.redis_enabled is true' do
    before do
      CoinPrice.configure do |config|
        config.redis_enabled = true
      end
    end

    after do
      CoinPrice.configure do |config|
        config.redis_enabled = false
      end
    end

    describe '#get' do
      it 'calls CoinPrice.redis.get' do
        expect(CoinPrice.redis).to receive(:get).with(key).once

        CoinPrice.cache.get(key)
      end
    end

    describe '#set' do
      it 'calls CoinPrice.redis.set' do
        expect(CoinPrice.redis).to receive(:set).with(key, value).once

        CoinPrice.cache.set(key, value)
      end
    end

    describe '#incrby' do
      it 'calls CoinPrice.redis.incrby' do
        expect(CoinPrice.redis).to receive(:incrby).with(key, number).once

        CoinPrice.cache.incrby(key, number)
      end
    end

    it 'can set and get a value' do
      CoinPrice.cache.set(key, value)

      expect(CoinPrice.cache.get(key)).to eq(value.to_s)
    end

    it 'can increment and get values' do
      CoinPrice.cache.incrby(key, 1)
      expect(CoinPrice.cache.get(key)).to eq('1')

      CoinPrice.cache.incrby(key, 1)
      expect(CoinPrice.cache.get(key)).to eq('2')

      CoinPrice.cache.incrby(key, 3)
      expect(CoinPrice.cache.get(key)).to eq('5')
    end
  end

  context 'when CoinPrice.config.redis_enabled is false' do
    before do
      CoinPrice.configure do |config|
        config.redis_enabled = false
      end
    end

    describe '#get' do
      it 'gets value locally' do
        expect(CoinPrice.cache.instance_variable_get(:@local)).to \
          receive(:[]).with(key.to_s).once

        CoinPrice.cache.get(key)
      end
    end

    describe '#set' do
      it 'sets value locally' do
        expect(CoinPrice.cache.instance_variable_get(:@local)).to \
          receive(:[]=).with(key.to_s, value.to_s).once

        CoinPrice.cache.set(key, value)
      end
    end

    describe '#incrby' do
      it 'increments value locally' do
        expect(CoinPrice.cache.instance_variable_get(:@local)).to \
          receive(:[]=).with(key.to_s, '1').once.and_call_original

        CoinPrice.cache.incrby(key, 1)

        expect(CoinPrice.cache.instance_variable_get(:@local)).to \
          receive(:[]=).with(key.to_s, '3').once

        CoinPrice.cache.incrby(key, 2)
      end
    end

    it 'can set and get a value' do
      CoinPrice.cache.set(key, value)

      expect(CoinPrice.cache.get(key)).to eq(value.to_s)
    end

    it 'can increment and get values' do
      CoinPrice.cache.incrby(key, 1)
      expect(CoinPrice.cache.get(key)).to eq('1')

      CoinPrice.cache.incrby(key, 1)
      expect(CoinPrice.cache.get(key)).to eq('2')

      CoinPrice.cache.incrby(key, 3)
      expect(CoinPrice.cache.get(key)).to eq('5')
    end
  end
end
