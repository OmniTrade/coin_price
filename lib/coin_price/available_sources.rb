module CoinPrice
  AVAILABLE_SOURCES = {
    'coinpaprika' => CoinPrice::Coinpaprika::Source,
    'coinmarketcap' => CoinPrice::CoinMarketCap::Source
  }
end
