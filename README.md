CoinPrice
=========

CoinPrice fetch cryptocurrency latest prices from a Source API and cache results
into an in-memory hash or into Redis. Price values are returned as BigDecimal
and timestamps as Integer Unix time.

__NOTE__: CoinMarketCap is currently set as the default price Source, but
CoinPrice is extensible by adding more Sources.

Install
-------

Build and install the gem locally:

```sh
gem build coin_price.gemspec
gem install coin_price-2.1.2.gem
```

Or install it from `rubygems.org` in your terminal:

```sh
gem install coin_price
```

Or via a `Gemfile`:

```Gemfile
source 'https://rubygems.org'

ruby '~> 2.5'

gem 'coin_price', '~> 2.1'
```

Require it in your Ruby code and `CoinPrice` module will be available.

```ruby
require 'coin_price'
```

Configure
---------

`CoinPrice` supports configuration with the `.configure` method, e.g.:

```ruby
# Example: setting up to use Redis.
CoinPrice.configure do |config|
  config.redis_enabled = true
  config.redis_url = 'redis://localhost:6379/0'
end
```

List of configuration values:

- `redis_enabled`: whether or not Redis should be used to cache values (defaults to `false`)
- `redis_url`: the Redis URL to cache values if enabled (defaults to `'redis://localhost:6379/0'`)
- `cache_key_prefix`: a custom prefix to be used in hash or Redis keys (defaults to an empty string)
- `default_source`: the default price Source to be used when none is specified (defaults to `'coinmarketcap'`)

(See `Config` class at `lib/coin_price/config.rb` for the up to date list of
configuration values)

__NOTE__: Each price Source may have its own configuration.

Price Sources
-------------

### CoinMarketCap

- ID: `'coinmarketcap'`
- Name: CoinMarketCap
- Website: https://coinmarketcap.com

`CoinPrice::CoinMarketCap` supports configuration with the `.configure` method.

Set your CoinMarketCap API Key (required):

```ruby
CoinPrice::CoinMarketCap.configure do |config|
  config.api_key = 'Your-CoinMarketCap-API-Key'
end
```

List of configuration values:

- `api_key`: your CoinMarketCap API Key (required; defaults to `nil`)
- `listings_limit`: number of results to return in the listings endpoint
  (defaults to `200` so it consumes only 1 call credit; max limit is `5000`;
  see https://coinmarketcap.com/api/documentation/v1/#operation/getV1CryptocurrencyListingsLatest)
- `wait_between_requests`: delay in seconds between calls to the listings endpoint (defaults to `1`)
- `max_request_retries`: number of retries before considering a request failed (defaults to `3`)

(See `Config` class at `lib/coin_price/coin_market_cap/config.rb` for more
CoinMarketCap configuration values)

Get latest price
----------------

```ruby
# Latest BTC price quoted in USD from CoinMarketCap
CoinPrice.value('BTC', 'USD', 'coinmarketcap')
# => 0.118503219133e5

# CoinMarketCap is currently set as the default source

CoinPrice.value('BTC', 'USD')
# => 0.118503219133e5

CoinPrice.value('LTC', 'BTC')
# => 0.103566820683796e-1
```

Get many latest prices
----------------------

```ruby
# List many latest prices at once
CoinPrice.values(['BTC', 'ETH' , 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# => {
#   "BTC" => {
#     "USD" => 0.118499825249e5,
#     "BTC" => 0.1e1,
#     "ETH" => 0.39987345861561e2
#   },
#   "ETH" => {
#     "USD" => 0.296343312355e3,
#     "BTC" => 0.250079113393039e-1,
#     "ETH" => 0.1e1
#   },
#   "LTC" => {
#     "USD" => 0.122730016464e3,
#     "BTC" => 0.10356978688037e-1,
#     "ETH" => 0.414148088879352e0
#   },
#   "XRP" => {
#     "USD" => 0.397052008421e0,
#     "BTC" => 0.33506548012766e-4,
#     "ETH" => 0.133983792401348e-2
#   }
# }
```

Cache
-----

All fetched prices are stored into an in-memory hash or Redis and can be used
instead of sending another request to the API:

```ruby
CoinPrice.value('BTC', 'USD', 'coinmarketcap', from_cache: true)
# => 0.118499825249e5

CoinPrice.timestamp('BTC', 'USD', 'coinmarketcap')
# => 1562250411

CoinPrice.values(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinmarketcap', from_cache: true)
# Yields the same previous result for many latest prices

CoinPrice.timestamps(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinmarketcap')
# Yields the same hash structure as the previous result for many latest prices,
# but with the timestamps instead of price values

# Number of requests performed today
CoinPrice.requests_count('coinmarketcap')
# => 6
```

### Keys and data

Cache keys of in-memory hash or Redis follow the pattern:
- `coin-price:{source}:value:{base}:{quote}`
- `coin-price:{source}:timestamp:{base}:{quote}`

Example:

```ruby
CoinPrice.cache.get('coin-price:coinmarketcap:value:BTC:USD')
# => "0.118499825249e5"
CoinPrice.cache.get('coin-price:coinmarketcap:timestamp:BTC:USD')
# => "1562250411"
```

Or in Redis:

```sh
$ redis-cli
> get coin-price:coinmarketcap:value:BTC:USD
> "0.118499825249e5"
> get coin-price:coinmarketcap:timestamp:BTC:USD
> "1562250411"
```

There is also a requests count at:
- `coin-price:{source}:requests-count:{date}`

Example:

```ruby
CoinPrice.cache.get('coin-price:coinmarketcap:requests-count:2019-07-04')
# => "6"
```

Or in Redis:

```sh
$ redis-cli
> get coin-price:coinmarketcap:requests-count:2019-07-04
> "6"
```

Refresher
---------

Refresher loops indefinitely and executes `CoinPrice.values` to populate the
in-memory hash or Redis with the specified coin prices.

```ruby
CoinPrice::Refresher.configure do |config|
  config.wait = 60 # seconds
end

CoinPrice::Refresher.call(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# Awake! Refreshing prices...
# Done refreshing prices! Sleeping...
```

List of configuration values:

- `wait`: delay in seconds to wait until the next refresh (defaults to `120`)
- `wait_weekday_multiplier`: multiplier to apply to `wait` when it a weekday (Monday to Friday)
- `wait_weekend_multiplier`: multiplier to apply to `wait` when it a weekend (Saturday and Sunday)

How to add a new source
-----------------------

* Create a new module at `lib/coin_price/your_new_source` and implement a
`Source < CoinPrice::Source` class with the methods `id` and `values`:
  - `id` must return a unique string that identifies your Source in the code
  - `values` must receive the params `bases, quotes` which are arrays of
    currency symbols and return a hash with the price values for each base and
    quote specified.
* Provide a test suite.
* Add a group in the `SimpleCov` at `spec/spec_helper.rb`
* Register your new source at `lib/coin_price/available_sources.rb` in the
  `AVAILABLE_SOURCES` constant
* Require it in `lib/coin_price.rb`

Optionally implement a `Config` class for you module and whichever class is
needed for it to work.

(See `CoinPrice::CoinMarketCap` module for an example)

Tests
-----

Run tests with:

```
bundle exec rspec
```

Linter
------

```sh
gem install rubocop

rubocop
```
