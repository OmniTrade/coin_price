module CoinPrice
  AVAILABLE_SOURCES = {
    'coinmarketcap' => CoinPrice::CoinMarketCap::Source,
    'coinpaprika' => CoinPrice::Coinpaprika::Source
  }
end
