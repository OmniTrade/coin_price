require 'simplecov'

SimpleCov.minimum_coverage(75)
SimpleCov.start do
  add_filter 'spec/'

  add_group 'CoinPrice', 'lib/coin_price'
  add_group 'CoinPrice::Refresher', 'lib/coin_price/refresher'
  add_group 'CoinPrice::Coinpaprika', 'lib/coin_price/coinpaprika'
  add_group 'CoinPrice::CoinMarketCap', 'lib/coin_price/coin_market_cap'
  add_group 'CoinPrice::PTAX', 'lib/coin_price/ptax'
  add_group 'CoinPrice::Omnitrade', 'lib/coin_price/omnitrade'
end

require_relative '../lib/coin_price'

require 'fakeredis/rspec'
require 'pry'

RSpec.configure do |config|
  config.before(:example) do
    CoinPrice.cache_reset
  end
end
