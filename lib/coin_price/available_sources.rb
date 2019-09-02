module CoinPrice
  AVAILABLE_SOURCES = [
    CoinPrice::Coinpaprika::Source,
    CoinPrice::CoinMarketCap::Source,
    CoinPrice::PTAX::Source,
    CoinPrice::Omnitrade::Source
  ]
end
