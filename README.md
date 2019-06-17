CoinPrice
=========

CoinPrice fetch cryptocurrency prices from a source API and cache results
into Redis. Prices are returned as BigDecimal.

__NOTE__: CoinMarketCap is currently set as the default source API, but
CoinPrice is extensible by adding more sources.

Install
-------

Build and install the gem:

```sh
gem build coin_price.gemspec
gem install coin_price-0.1.0.gem
```

Require it in your Ruby code and `CoinPrice` module will be available.

```ruby
require 'coin_price'
```

Configure
---------

See `Config` class at `lib/coin_price/config.rb` for the list of configuration
values.

```ruby
# Set your CoinMarketCap API Key
CoinPrice.configure do |config|
  config.coinmarketcap_api_key = 'Your-CoinMarketCap-API-Key'
end
```

Get latest price
----------------

```ruby
# Latest BTC price quoted in USD from CoinMarketCap
CoinPrice.latest('BTC', 'USD', 'coinmarketcap')
# => 0.90007962389e4

# CoinMarketCap is currently set as the default source
CoinPrice.latest('BTC', 'USD')
# => 0.90007962389e4
CoinPrice.latest('LTC', 'BTC')
# => 0.298472478320223e-1
```

Get list of latest prices
-------------------------

```ruby
# Listings many latest prices at once
CoinPrice.listings(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# => {
#   "BTC" => {
#     "USD" => 0.900291185472e4,
#     "BTC" => 0.1e1,
#     "ETH" => 0.33514171528566e2
#   },
#   "ETH" => {
#     "USD" => 0.268629998717e3,
#     "BTC" => 0.298381238261445e-1,
#     "ETH" => 0.1e1
#   },
#   "LTC" => {
#     "USD" => 0.136720443221e3,
#     "BTC" => 0.15186247008441e-1,
#     "ETH" => 0.508954487116065e0
#   },
#   "XRP" => {
#     "USD" => 0.424051189063e0,
#     "BTC" => 0.471015595738262e-4,
#     "ETH" => 0.157856974682018e-2
#   }
# }
```

Cache
-----

All fetched prices are stored in Redis and can be used instead sending another
request to the API:

```ruby
CoinPrice.latest('BTC', 'USD', 'coinmarketcap', from_cache: true)
# => 0.900291185472e4

CoinPrice.listings(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinmarketcap', from_cache: true)
# yields the same previous result for listings
```

Cache keys in Redis follow the pattern:
- `coin-price:{source}:value:{base}:{quote}`
- `coin-price:{source}:timestamp:{base}:{quote}`

Example:
```sh
$ redis-cli
> get coin-price:coinmarketcap:value:BTC:USD
> "0.901072379743e4"
> get coin-price:coinmarketcap:timestamp:BTC:USD
> "1560720768"
```

There is also a requests count at:
- `coin-price:{source}:requests-count:{date}`

Example:
```sh
$ redis-cli
> get coin-price:coinmarketcap:requests-count:2019-06-16
> "6"
```

Refresher
---------

Refresher loops indefinitely and executes `CoinPrice.listings` to populate
Redis cache with the specified coin prices.

```ruby
CoinPrice.configure do |config|
  config.refresher_wait = 60 # seconds
end

CoinPrice::Refresher.call(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# Awake! Refreshing prices...
# Done refreshing prices! Sleeping...
```
