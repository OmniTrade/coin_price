CoinPrice
=========

CoinPrice fetch cryptocurrency latest prices from a source API and cache results
into Redis. Price values are returned as BigDecimal and timestamps as Integer
Unix time.

__NOTE__: CoinMarketCap is currently set as the default source API, but
CoinPrice is extensible by adding more sources.

Install
-------

Build and install the gem:

```sh
gem build coin_price.gemspec
gem install coin_price-2.0.0.gem
```

Require it in your Ruby code and `CoinPrice` module will be available.

```ruby
require 'coin_price'
```

Configure
---------

See `Config` class at `lib/coin_price/config.rb` for the list of configuration
values.

Each source may have its own configuration.

### CoinMarketCap

Set your CoinMarketCap API Key:

```ruby
CoinPrice::CoinMarketCap.configure do |config|
  config.api_key = 'Your-CoinMarketCap-API-Key'
end
```

See `Config` class at `lib/coin_price/coin_market_cap/config.rb` for more
CoinMarketCap configuration values.

Get latest price
----------------

```ruby
# Latest BTC price quoted in USD from CoinMarketCap
CoinPrice.value('BTC', 'USD', 'coinmarketcap')
# => 0.90007962389e4

# CoinMarketCap is currently set as the default source

CoinPrice.value('BTC', 'USD')
# => 0.90007962389e4

CoinPrice.value('LTC', 'BTC')
# => 0.298472478320223e-1
```

Get many latest prices
----------------------

```ruby
# List many latest prices at once
CoinPrice.values(['BTC', 'ETH' , 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
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

All fetched prices are stored in Redis and can be used instead of sending
another request to the API:

```ruby
CoinPrice.value('BTC', 'USD', 'coinmarketcap', from_cache: true)
# => 0.900291185472e4

CoinPrice.timestamp('BTC', 'USD', 'coinmarketcap')
# => 1560720701

CoinPrice.values(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinmarketcap', from_cache: true)
# Yields the same previous result for many latest prices

CoinPrice.timestamps(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinmarketcap')
# Yields the same hash structure as the previous result for many latest prices,
# but with the timestamps instead of price values
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

Refresher loops indefinitely and executes `CoinPrice.values` to populate Redis
cache with the specified coin prices.

```ruby
CoinPrice::Refresher.configure do |config|
  config.wait = 60 # seconds
end

CoinPrice::Refresher.call(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# Awake! Refreshing prices...
# Done refreshing prices! Sleeping...
```

How to add another source
-------------------------

Create a new module at `lib/coin_price/your_new_source` and implement a
`Source < CoinPrice::Source` class with the methods `self.id` and `values`:

- `self.id` must return a unique string that identifies your Source in the code
- `values` must receive the params `bases = [], quotes = []` and
  return a hash with the price values for each base and quote currencies specified.

Then register your new source at `lib/coin_price/config.rb` in the
`AVAILABLE_SOURCES` constant and require it in `lib/coin_price.rb`

Optionally implement a `Config` class for you module and whichever class is
needed for it to work.

(See `CoinMarketCap` module for an example)

Tests
-----

Run tests with `bundle exec rspec`

Linter
------

```sh
gem install rubocop

rubocop
```
