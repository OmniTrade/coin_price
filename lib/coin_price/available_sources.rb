module CoinPrice
  AVAILABLE_SOURCES = [
    CoinPrice::Coinpaprika::Source,
    CoinPrice::CoinMarketCap::Source
  ]
end
