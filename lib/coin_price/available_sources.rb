module CoinPrice
  AVAILABLE_SOURCES = [
    CoinPrice::Coinpaprika::Source,
    CoinPrice::CoinMarketCap::Source,
    CoinPrice::PTAX::Source
  ]
end
